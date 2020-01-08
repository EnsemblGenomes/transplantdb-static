#!/bin/bash


# the site url, eg local-prod-portals.biotnet.org,
SITE=www.transplantdb.eu

# output base directory, eg /var/www
# site will be in a subfolder of this site according to SITE above, eg /var/www/local-prod-portals.biotnet.org
BASE=.

# the archive notice html, will get added to top of all pages
NOTICE='<div style="padding:1em;margin:1em;border:1px solid #444;background:#ccc;color:#222;text-align:center">This site is no longer maintained and is provided for reference only. Some functionality or links may not work. For all enquiries please contact the <a href="http://www.ensembl.org/info/about/contact/index.html">Ensembl Helpdesk</a>.</div>';

read -p "Spidering $SITE to $BASE/$SITE, 'y' to continue? " ANSWER;
if [ "$ANSWER" != "y" ]; then exit; fi;

# convert SITE into DOMAIN and DIRECTORY parts
DOMAIN=$(echo $SITE | cut -d/ -f1);
DIRECTORY=${SITE#$DOMAIN}
DIRECTORY=${DIRECTORY:1}

echo "Domain = $DOMAIN";
echo "Directory = $DIRECTORY"

# create regex version of above
NOTICE_REGEX="${NOTICE////\\/}"; # escape slashes
NOTICE_REGEX="${NOTICE_REGEX//\"/\\\"}"; # escape quotes
NOTICE_REGEX="${NOTICE_REGEX//./\\.}"; # escape dots

DOMAIN_REGEX="https?:\/\/${DOMAIN//./\.}"; # escape dots, add protocol

DIRECTORY_REGEX="${DIRECTORY////\/}"; # escape slashes
if [ -n "$DIRECTORY_REGEX" ];
then
  DIRECTORY_REG="${DIRECTORY_REGEX}|"; # add trailing OR
fi;

# change to base directory
cd $BASE
# clear any previous attempt
rm -rf $SITE

# make a mirror
echo "Getting site content..."
wget --mirror --html-extension --execute=robots=off --page-requisites --base=./ --directory-prefix=./ --domains=${DOMAIN} --output-file=/dev/stdout --no-verbose http://${SITE} | tee ${SITE}.log;

# change to site
cd $SITE;

# for sites in subdirectory, create an index.html for base
if [ -f ../$(basename $PWD).html ];
then
  echo "Creating index.html..."
  mv -v ../$(basename $PWD).html index.html
fi;

# get not-found page
echo "Getting not-found page..."
curl -o not-found.html http://$SITE/not-found;
find . -name "not-found.html" -type f -print0 | xargs -0 perl -i -pe "s/\"[^\"]*\/not-found\" //g";


# remove query string from files
# rename some .1.html files
echo "Fixing file names..."
for i in $(find . -depth -type f -name "*\?*" -not -name "*.html" );
do
  mv -v $i $(echo $i | sed 's/\?.*//');
done;
for i in $(find . -depth -type f -name "*.1.html");
do
  mv -v $i $(echo $i | sed 's/\.1//');
done;

# remove /user pages
echo "Removing user login pages..."
rm -vrf user.html user

# remove absolute url
echo "Removing absolute urls from source..."
find . -name "*.html" -type f -print0 | xargs -0 perl -i -pe "s/${DOMAIN_REGEX}//g";

# ensure asset requests have leading slash
echo "Checking asset locations in source..."
find . -name "*.html" -type f -print0 | xargs -0 perl -i -pe "s/((src\s*=\s*|href\s*=\s*|url\s*\(\s*)[\"'])(${DIRECTORY_REGEX}sites|modules|misc|profiles|scripts|themes|includes)/\1\/\3/g";

# add comment to all html files
echo "Adding notice to all pages..."
find . -name "*.html" -type f -print0 | xargs -0 perl -i -pe "s/(<body[^>]+>)/\1\n<\!-- static copy: $(date) -->\n${NOTICE_REGEX}/g";

# create .htaccess
echo "Creating .htaccess"
echo 'RewriteEngine On' > .htaccess
echo '' >> .htaccess
echo 'RewriteCond %{REQUEST_FILENAME} !-f' >> .htaccess
echo 'RewriteCond %{REQUEST_FILENAME}/index\.html -f' >> .htaccess
echo "RewriteRule ^$ index.html [L]" >> .htaccess
echo '' >> .htaccess
echo 'RewriteCond %{REQUEST_FILENAME} !-f' >> .htaccess
echo 'RewriteCond %{REQUEST_FILENAME}\.html -f' >> .htaccess
echo 'RewriteRule ^(.*)$ $1.html [L]' >> .htaccess

# list problem files
echo ""
echo "Any problem files will be listed below:"
find . -depth -type f -name "*\?*" -ls
find . -depth -type f -size 0 -ls
find . -depth -type f -name "*.1.html" -ls
find . -depth -type f -name "*.2.html" -ls
echo '-- end of problem files'

