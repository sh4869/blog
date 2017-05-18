@echo off
cd public 
rm -rf *
cd ..
@hugo
cd public
git add -A
git commit -m "UPDATE - %DATE% %TIME%"
git push origin gh-pages
cd ..
