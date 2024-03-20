# i18n_editor

i18n editor for editing json files with translations.

after opening a folder we find every json file in the folder and add it to the list of the json files to read and write to.

each json file contains key value pairs of translations.
the value could be a string or an object with a key value pairs of translations.

we must sync the keys between all the files and have a tree in the ui representing all the keys and sub keys.

when we select a key we must see the translations of that key in all the files and have textfields for each of the languages to edit the translations.

---
i18n project file content (.i18n_configs.yaml):
file_prefix: strings

---

## TODO

- [ ] Change the state structure to maps
- [ ] Drag and drop keys to move them into or out of sub keys
- [ ] Add new language
- [x] Rename keys
- [ ] Option to choose the base file instead of basing it on the prefix
- [ ] New layout to view all keys for all languages in a list view
