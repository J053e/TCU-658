# Asset Structure (Godot 4)

This project uses a zone-first asset layout with shared reusable folders.

## Required Global Icons (always present)
Place these exact files here:

- assets/branding/global_icons/elm.png
- assets/branding/global_icons/tcu658.png
- assets/branding/global_icons/ucr.png

## Zone folders
Each zone has folders for:
- backgrounds
- characters
- objects
- interactive
- ui

## Shared folders
Use `assets/shared/*` for files reused across two or more zones.

## Naming convention
Use lowercase snake_case:
- bg_school_gate_day.png
- char_teacher_idle.png
- obj_notebook_closed.png
- int_door_main.png
- icon_stamp_gold.png

## Formats
- Backgrounds: PNG/JPG (recommended 1280x720)
- Interactive objects, icons, characters: PNG (transparent)
- Audio: OGG/WAV
