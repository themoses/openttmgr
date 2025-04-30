# openttmgr
Open Source tool to manage tiptoi® by Ravensburger®

## Features
- [x] List files on tiptoi®
- [x] Find files by name
- [x] Find files by ISBN
- [x] Find files by Article Number
- [ ] Find files by EAN
- [ ] Firmware update

## Idea
Ravensburger offers an official application in order to manage the files of the tiptoi® products. Unfortunately, there is no Linux support, so this tool aims to fill that gap. It takes a word and uses the search to find matching tiptoi® products. The respective GME file can then be automatically downloaded to the tiptoi®.

## Dependencies

### For bash script
- `bash`
- `jq`
- `curl`
- `wget`

### For python
- `pip3`
- `click`

## How to

Download the script from here or clone the repository. Run the script and pass the search query as a __*quoted string*__

```bash
./openttmgr.sh "feuerwehr"

./openttgr.py --title feuerwehr
```


## References

The following resources were used in order to write this tool

* https://wiki.ubuntuusers.de/tiptoi/
