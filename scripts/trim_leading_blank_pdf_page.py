#!/usr/bin/env python3

"""Remove a genuinely empty leading page from a PDF, if one exists."""

from pathlib import Path
import sys

from pypdf import PdfReader, PdfWriter


def page_is_empty(page) -> bool:
    return not (page.extract_text() or "").strip() and not page.get_contents()


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: trim_leading_blank_pdf_page.py PDF_PATH")

    pdf_path = Path(sys.argv[1]).resolve()
    reader = PdfReader(pdf_path)
    if len(reader.pages) < 2 or not page_is_empty(reader.pages[0]):
        return 0

    writer = PdfWriter()
    for page in reader.pages[1:]:
        writer.add_page(page)
    if reader.metadata:
        writer.add_metadata(reader.metadata)

    temporary_path = pdf_path.with_suffix(".trimmed.pdf")
    with temporary_path.open("wb") as stream:
        writer.write(stream)
    temporary_path.replace(pdf_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
