# ExerciseMgr

An application for selection and arrangement of exercises from a database

## Links

[Repo Structure](presentations/Stucture.pdf)<br/>
[Timetable](presentations/ExerciseMgr_Overview.pdf)<br/>
[Database Spreadsheet](https://docs.google.com/spreadsheets/d/1Lylci601lkUr0L-GBdMdQOvSfVu1yNaE8roOhhNNHXI/edit?usp=sharing) <br/>
[overview important classes (gui)](presentations/overview_important_classes.pdf)<br/>
[Main Loop](presentations/Main_loop.pdf)<br/>
[The Kv-language](presentations/The_kv_language.pdf)<br/>
[Edit/change gui elements](presentations/Edit_and_change_gui_elements.pdf)<br/>
[Creating the Database](presentations/Create_Database.pdf)<br/>
[Guide for further development](presentations/Quickstart.pdf)<br/>
[Presentations](presentations)

## SQLite Viewer
[Link](http://inloop.github.io/sqlite-viewer/)

## Setup

```sh
pip3 install -r requirements.txt
```

## Execution

```
python3 -m exercise_mgr.populate.0_create_database
python3 -m exercise_mgr.populate.1_populate_topics
python3 -m exercise_mgr.populate.2_prepare_topics
python3 -m exercise_mgr.populate.3_prepare_files
python3 -m exercise_mgr.populate.4_populate_files
```
