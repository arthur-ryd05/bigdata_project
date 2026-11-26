"""Extraction reproductible du sous-ensemble brut du jeu Berka (PKDD'99).

Source : depot GitHub jlacko/berka-dataset, epingle sur un commit precis.
Le script ne transforme aucune ligne : il copie les octets d'origine
(CRLF, guillemets, separateur ';') et ne fait que filtrer trans.asc.

    python3 src/ingestion/extract_berka.py --out data/bronze
    python3 src/ingestion/extract_berka.py --source-dir /chemin/clone --out data/bronze

Sorties : order.asc, account.asc, loan.asc, trans.asc (virements emis
du 2e semestre 1998) et manifest.json (tailles, lignes, sha256).
Bibliotheque standard uniquement : tourne dans n'importe quel pod python.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
import urllib.request
from datetime import datetime, timezone

SOURCE_REPO = "https://github.com/jlacko/berka-dataset"
SOURCE_COMMIT = "77e9972a1ead107e5f42a91dd989d587bff055a4"
RAW_URL = "https://raw.githubusercontent.com/jlacko/berka-dataset/{commit}/{name}"

# Empreintes des fichiers sources complets, verifiees avant extraction.
SOURCE_SHA256 = {
    "order.asc": "035930fa6acd2ca42a935e654b21e1bb260248f49b6dc6e7de6351b7c4d56d02",
    "account.asc": "58d7f50abd72e9b1a5568346f74bb54cd71224ee1db9f09a27d7cac563f38cc6",
    "loan.asc": "68535f609a254aa7a3f03dd8e27dcb822b532df12a0d6046f0666b8dc0b8ae8e",
    "trans.asc": "75ab2f39df9d79d79c5c900de90ddd28248b689f214598ac9fa2ff0f574a70d2",
}

# Perimetre du releve : virements emis vers une autre banque, juillet-decembre 1998.
TRANS_OPERATION = b'"PREVOD NA UCET"'
DATE_MIN, DATE_MAX = 980701, 981231


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_source(name: str, source_dir: pathlib.Path | None) -> bytes:
    if source_dir is not None:
        data = (source_dir / name).read_bytes()
    else:
        url = RAW_URL.format(commit=SOURCE_COMMIT, name=name)
        print(f"telechargement {url}", file=sys.stderr)
        with urllib.request.urlopen(url, timeout=300) as resp:
            data = resp.read()
    digest = sha256(data)
    if digest != SOURCE_SHA256[name]:
        raise SystemExit(f"{name}: sha256 inattendu {digest}, source modifiee ?")
    return data


def filter_transfers(data: bytes) -> tuple[bytes, int]:
    """Garde l'en-tete et les virements emis de la periode, octets inchanges."""
    lines = data.splitlines(keepends=True)
    kept = [lines[0]]
    for line in lines[1:]:
        fields = line.rstrip(b"\r\n").split(b";")
        # trans_id;account_id;date;type;operation;amount;balance;k_symbol;bank;account
        if fields[4] != TRANS_OPERATION:
            continue
        if DATE_MIN <= int(fields[2]) <= DATE_MAX:
            kept.append(line)
    return b"".join(kept), len(kept) - 1


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=pathlib.Path, default=pathlib.Path("data/bronze"))
    parser.add_argument("--source-dir", type=pathlib.Path, default=None,
                        help="clone local du depot source (sinon telechargement)")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)

    outputs: dict[str, tuple[bytes, int]] = {}
    for name in ("order.asc", "account.asc", "loan.asc"):
        data = load_source(name, args.source_dir)
        outputs[name] = (data, data.count(b"\n") - 1)
    outputs["trans.asc"] = filter_transfers(load_source("trans.asc", args.source_dir))

    manifest = {
        "dataset": "Berka financial dataset (PKDD'99 Discovery Challenge)",
        "source_repo": SOURCE_REPO,
        "source_commit": SOURCE_COMMIT,
        "extracted_at_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "filter_trans": f"operation=PREVOD NA UCET and {DATE_MIN}<=date<={DATE_MAX}",
        "files": {},
    }
    total = 0
    for name, (data, rows) in outputs.items():
        (args.out / name).write_bytes(data)
        total += len(data)
        manifest["files"][name] = {"bytes": len(data), "rows": rows, "sha256": sha256(data)}
    manifest["total_bytes"] = total
    (args.out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")

    for name, meta in manifest["files"].items():
        print(f"{name:12} {meta['rows']:>7} lignes {meta['bytes']:>9} octets")
    print(f"total        {total:>25} octets ({total / 1e6:.2f} Mo)")
    if not 1_000_000 <= total <= 5_000_000:
        raise SystemExit("taille brute hors de l'intervalle 1-5 Mo impose par le sujet")


if __name__ == "__main__":
    main()
