#!/usr/bin/env python3
"""
Search a PDF for lines matching some text, and report where they are.

Prints every matching line with its page number. Useful for pulling specific
entries out of long statements, reports or exports without opening them.

Requires pdfplumber:  python -m pip install pdfplumber

Examples
--------
  # every line containing "Invoice" (case-sensitive substring, the default)
  python pdf_search.py statement.pdf "Invoice"

  # case-insensitive
  python pdf_search.py statement.pdf "invoice" -i

  # only lines that START with the text
  python pdf_search.py report.pdf "Total" --starts-with

  # regular expression: any amount in euros
  python pdf_search.py statement.pdf "EUR ?[0-9.,]+" -r

  # save the results instead of printing them
  python pdf_search.py report.pdf "Total" -o totals.txt
"""

import argparse
import re
import sys

try:
    import pdfplumber
except ImportError:
    sys.exit(
        "pdfplumber is required but not installed. Install it with:\n"
        "    python -m pip install pdfplumber"
    )


# Soft hyphens are invisible but break naive matching, so they are stripped
# before comparing. Anything else in the extracted text is left alone.
SOFT_HYPHEN = "­"


def build_matcher(pattern, *, regex=False, ignore_case=False, starts_with=False):
    """Return a predicate that decides whether one line matches."""
    if regex:
        try:
            compiled = re.compile(pattern, re.IGNORECASE if ignore_case else 0)
        except re.error as exc:
            sys.exit(f"Invalid regular expression: {exc}")
        # re.match anchors at the start, re.search looks anywhere.
        return compiled.match if starts_with else compiled.search

    if ignore_case:
        needle = pattern.casefold()
        return (lambda line: line.casefold().startswith(needle)) if starts_with \
            else (lambda line: needle in line.casefold())

    return (lambda line: line.startswith(pattern)) if starts_with \
        else (lambda line: pattern in line)


def search_pdf(pdf_path, matches):
    """Yield (page_number, line) for every line the matcher accepts."""
    with pdfplumber.open(pdf_path) as pdf:
        for page_number, page in enumerate(pdf.pages, start=1):
            try:
                text = page.extract_text()
            except Exception as exc:
                # One unreadable page shouldn't abandon the whole document.
                print(f"Warning: skipping page {page_number}: {exc}", file=sys.stderr)
                continue

            if not text:
                continue  # image-only page, or genuinely empty

            for line in text.replace(SOFT_HYPHEN, "").splitlines():
                line = line.strip()
                if line and matches(line):
                    yield page_number, line


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Search a PDF for lines matching some text.",
        epilog="Exits 1 if nothing matched, so it composes with shell scripts.",
    )
    parser.add_argument("pdf", help="path to the PDF file")
    parser.add_argument("text", help="text or regular expression to look for")
    parser.add_argument(
        "-i", "--ignore-case", action="store_true",
        help="match regardless of case",
    )
    parser.add_argument(
        "-r", "--regex", action="store_true",
        help="treat TEXT as a regular expression instead of literal text",
    )
    parser.add_argument(
        "--starts-with", action="store_true",
        help="only match lines that begin with TEXT (default: match anywhere in the line)",
    )
    parser.add_argument(
        "-o", "--output", metavar="FILE",
        help="write results to FILE instead of standard output",
    )
    parser.add_argument(
        "-q", "--quiet", action="store_true",
        help="print only the matching lines, without the header or match count",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    matcher = build_matcher(
        args.text,
        regex=args.regex,
        ignore_case=args.ignore_case,
        starts_with=args.starts_with,
    )

    try:
        results = list(search_pdf(args.pdf, matcher))
    except FileNotFoundError:
        sys.exit(f"No such file: {args.pdf}")
    except Exception as exc:
        sys.exit(f"Could not read {args.pdf}: {exc}")

    lines = []
    if not args.quiet:
        lines.append(f"File:    {args.pdf}")
        lines.append(f"Search:  {args.text}")
        lines.append(f"Matches: {len(results)}")
        lines.append("=" * 72)
        lines.append("")
    lines.extend(f"Page {page}: {line}" for page, line in results)

    report = "\n".join(lines) + ("\n" if lines else "")

    if args.output:
        try:
            with open(args.output, "w", encoding="utf-8", errors="replace") as handle:
                handle.write(report)
        except OSError as exc:
            sys.exit(f"Could not write {args.output}: {exc}")
        if not args.quiet:
            print(f"{len(results)} match(es) written to {args.output}")
    else:
        # errors="replace" equivalent for consoles that can't encode a glyph.
        sys.stdout.reconfigure(errors="replace")
        print(report, end="")

    return 0 if results else 1


if __name__ == "__main__":
    sys.exit(main())
