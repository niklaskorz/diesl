from pathlib import Path


class Settings:
    database = Path(__file__).parents[1] / "data" / "ibn.sqlite"
    items_per_page = 15
    years_to_go_back = 10  # possible number of years to choose from on button "not used since"
    files = Path(__file__).parents[1] / "data" / "files"
    save_path = Path(__file__).parent / "generated_pdf_and_tex"
