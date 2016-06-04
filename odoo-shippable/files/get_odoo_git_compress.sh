# Run follow commands to re-create odoo compress folder in local
# and after upload.
git init --bare ${HOME}/odoo_git_compress/.git \
 ; git --git-dir=${HOME}/odoo_git_compress/.git remote add odoo https://github.com/odoo/odoo.git \
 ; git --git-dir=${HOME}/odoo_git_compress/.git remote add oca https://github.com/oca/ocb.git \
 ; git --git-dir=${HOME}/odoo_git_compress/.git remote add vauxoo https://github.com/vauxoo/odoo.git \
 ; git --git-dir=${HOME}/odoo_git_compress/.git fetch --all \
 && du -sh ${HOME}/odoo_git_compress/.git \
 && unbuffer git --git-dir=${HOME}/odoo_git_compress/.git gc --aggressive \
 && du -sh ${HOME}/odoo_git_compress/.git \
 && rm -f ${HOME}/odoo_git.tar.gz \
 && tar -zcvf ${HOME}/odoo_git.tar.gz -C ${HOME}/odoo_git_compress .git \
 && echo "Now you can upload the file ${HOME}/odoo_git.tar.gz"
