# openttmgr
Open Source tool to manage TipToi by Ravensburger®

## Features
- [x] List files on TipToi
- [ ] Search files by name
- [ ] Search files by ISBN
- [ ] Firmware update

## Idea
Ravensburger offers an official application in order to manage the files of the tiptoi products. Unfortunately, there is no Linux support, so this tool aims to fill that gap.

### API search
Taken from the dev console, the API is able to return queries as json which can be then parsed by `jq
```bash
curl --silent 'https://service.ravensburger.de/@api/deki/site/query?dream.out.format=json&origin=mt-web&limit=10&offset=0&q=feuerwehr&sortBy=-rank&aggpath=&classifications=&includeaggs=true&namespaces=main&pathancestors=&recommendedids=&tags=&types=wiki&notrack=false&parser=bestguess' | jq .
# jq select link and regex to dl link
curl --silent 'https://service.ravensburger.de/tiptoi%C2%AE/tiptoi%C2%AE_Audiodateien/Audiodateien_tiptoi%C2%AE_B%C3%BCcher/tiptoi%C2%AE_Mein_gro%C3%9Fer_Weltatlas_32911' | grep --only-matching --perl-regexp "(\"https:\/\/ravensburger\.cloud\/rvwebsite\/rvDE\/db\/applications\/[[:alnum:]].*\.gme\")" | cut -d " " -f1
```


## References

The following resources were used in order to write this tool

* https://wiki.ubuntuusers.de/tiptoi/
