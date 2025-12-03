# Git edit commit history for large files 
By: VB @vboatwright


Successful steps to rewrite the history : 
What's happened: you have a rejected commit due to large file sizes. 

[After removing/editing the large files and saving them as small versions] 
Check everything 

```
$ git status 
```

Make a clean copy of repository history 


## Move to the top of your repo

```
$ cd /path/to/repository_of_interest
```

E.g.

```
$ cd /path/to/estuaries
```

## Make sure you're on your local main branch

```
$ git checkout main
```

## Create a backup branch as a backup in case of errors
```
$ git branch backup_before_cleanup
```

Use Git’s history rewrite tool to remove big files

```
$ git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch storms/analysis/day_cycle/LPL_diurnal_cycle.ipynb;

git rm --cached --ignore-unmatch storms/analysis/tidal_cycle/tidal_cycle_analysis_backup.ipynb' \
--prune-empty --tag-name-filter cat -- --all
```


**Note: git filter-branch will not touch your working directory. In the past I’ve used filter-repo, which edits your .git file and can cause for massive data loss from your local machine. Github prefers filter-repo (because… it’s faster? idk) but i do not. 


# Clean up and reduce repo size 


## 1. Remove the backup refs that filter-branch created
```
rm -rf .git/refs/original
```

## 2. Expire reflog entries so they don't keep the old commits alive
```
git reflog expire --expire=now --all
```

## 3. "Aggressively" garbage-collect unreachable objects (cleans up the repo for anything that is not touchable by git)
```
git gc --prune=now --aggressive
```

Check file sizes to ensure that you have removed the large files 

```
git rev-list --objects --all \

  | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \

  | sed -n 's/^blob //p' \

  | sort -n -k2 \

  | tail -n 20
```

Push safely

```
$ git push origin main --force-with-lease
```

### Automate the process
I also finally made an executable that will check for large files before communicating with github. You would put it in your .git in /repo/.git/hooks/: 

Create .git/hooks/pre-commit:
```bash
#!/bin/sh

# Maximum file size in bytes (100 MB)

max_size=100000000


for file in $(git diff --cached --name-only); do

  if [ -f "$file" ]; then

    size=$(wc -c <"$file")

    if [ "$size" -gt "$max_size" ]; then

      echo "ERROR: $file is too large ($size bytes). Commit rejected."

      exit 1

    fi

  fi

done
```
Make executable with chmod +x .git/hooks/pre-commit


From repo directory: 
```
$ chmod +x .git/hooks/pre-commit
```

Just wanted to forward them along if they'd be helpful for others too! 

Best, 

--Victoria 