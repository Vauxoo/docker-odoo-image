# Run follow commands to re-create odoo compress folder in local
# and after upload.
git init ${HOME}/odoo/ \
 ; git --git-dir=${HOME}/odoo/.git remote add odoo https://github.com/odoo/odoo.git \
 ; git --git-dir=${HOME}/odoo/.git remote add oca https://github.com/oca/ocb.git \
 ; git --git-dir=${HOME}/odoo/.git remote add vauxoo https://github.com/vauxoo/odoo.git \
 ; git --git-dir=${HOME}/odoo/.git fetch --all \
 && du -sh ${HOME}/odoo/.git \
 && unbuffer git --git-dir=${HOME}/odoo/.git gc --aggressive \
 && du -sh ${HOME}/odoo/.git \
 && tar -zcvf ${HOME}/odoo_git.tar.gz ${HOME}/odoo/.git
 && echo "Now you can upload the file ${HOME}/odoo_git.tar.gz"

 # && mkdir -p ${HOME}/addons-vauxoo/ \
 # && git init ${HOME}/addons-vauxoo/ \
 # && git --git-dir=${HOME}/addons-vauxoo/.git remote add vauxoo https://github.com/vauxoo/addons-vauxoo.git \
 # && git --git-dir=${HOME}/addons-vauxoo/.git fetch --all \
 # && du -sh ${HOME}/addons-vauxoo/.git \
 # && unbuffer git --git-dir=${HOME}/addons-vauxoo/.git gc --aggressive \
 # && du -sh ${HOME}/addons-vauxoo/.git


