#!/usr/bin/env python3
import sys
from pathlib import Path

from acme_doc_convert import main


if __name__ == "__main__":
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("src_acme/tutorial")
    dst = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("src_kick/tutorial")
    raise SystemExit(main([sys.argv[0], "kick", str(src), str(dst)]))
