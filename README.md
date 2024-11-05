# openttmgr
Open Source tool to manage TipToi by Ravensburger®

## Features
- [x] List files on TipToi
- [x] Find files by name
- [x] Find files by ISBN
- [x] Find files by Article Number
- [ ] Find files by EAN
- [ ] Firmware update

## Idea
Ravensburger offers an official application in order to manage the files of the tiptoi products. Unfortunately, there is no Linux support, so this tool aims to fill that gap.

### API search
Taken from the dev console, the API is able to return queries as json which can be then parsed by `jq
```bash
curl --silent 'https://service.ravensburger.de/@api/deki/site/query?dream.out.format=json&q=feuerwehr&type=books&sortBy=-rank&parser=bestguess' | jq -r .result[].title
# jq select link and regex to dl link
curl --silent 'https://service.ravensburger.de/tiptoi%C2%AE/tiptoi%C2%AE_Audiodateien/Audiodateien_tiptoi%C2%AE_B%C3%BCcher/tiptoi%C2%AE_Mein_gro%C3%9Fer_Weltatlas_32911' | grep --only-matching --perl-regexp "(\"https:\/\/ravensburger\.cloud\/rvwebsite\/rvDE\/db\/applications\/[[:alnum:]].*\.gme\")" | cut -d " " -f1 | xargs wget
```


## References

The following resources were used in order to write this tool

* https://wiki.ubuntuusers.de/tiptoi/
