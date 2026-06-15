English Passport exports

windows_single_exe/
- Closed portable builds.
- win64/EnglishPassport.exe runs on 64-bit Windows.
- win32/EnglishPassport.exe runs on 32-bit Windows.
- Each build is a single .exe. No extra folders are required.

windows_editable/
- Editable portable builds.
- win64/EnglishPassportEditable.exe runs on 64-bit Windows.
- win32/EnglishPassportEditable.exe runs on 32-bit Windows.
- Keep the content folder next to the executable.
- Edit JSON files in content/data to add or modify expandable questions.
- New external images can be placed in content/images and referenced as content://images/file.png.
- New external audio can be placed in content/audio and referenced as content://audio/file.ogg, .mp3, or .wav.