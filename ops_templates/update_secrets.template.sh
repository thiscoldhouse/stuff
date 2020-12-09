# Intended usage:
# update_env.sh /path/to/secretfile

# to encrypt your file:
# gpg -c /path/to/secretfile

# Result:
# - will drop a new version of secretfile in the same dir as secretfile.pgp

# Checks:
# - asks if you want to overwrite existing before continuing


#  =================== handy yaml parsing i took from SO  =================== #
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'

}

#  =================== check if file exists  ===================
if [ -f $(dirname $1)/$secrets ];
then
    read -r -p "File $secrets already exists, are you sure? The old one will be moved to $secrets.bck if you continue[y/N] " response
    case "$response" in
	[yY][eE][sS]|[yY])
	    echo "Great, continuing"
	    mv $(dirname $1)/$secrets $(dirname $1)/$secrets.bck
	    echo "Current $secrets moved to $secrets.bck"
            ;;
	*)
	    echo "Exiting safely"
	    exit 0
            ;;
    esac
fi

# =================== FOR YAML FILES  =================== #
# check that every variable specified in dev is also in prod
for devvar in  $(gpg --pinentry-mode=loopback --decrypt $1 | parse_yaml | grep dev);
do
    devvar="${devvar/dev_/}"
    devvar=(${devvar//=/ })
    devvar=${devvar[0]}
    FOUND=0
    if [[ $devvar == *"dev"* ]];
       # this makes sure dev isn't in the value, but in the
       # actual variable name
    then
	for prodvar in $(gpg --pinentry-mode=loopback --decrypt $1 | parse_yaml | grep prod)
	do
	    prodvar="${prodvar/prod_/}"
	    prodvar=(${prodvar//=/ })
	    prodvar=${prodvar[0]}
	    if [ "$devvar" == "$prodvar" ]; then
		FOUND=1
		break
	    fi
	done
	if [ $FOUND == 0 ]; then
	    echo "Missing variable $devvar in production, exiting safely"
	    exit 1
	fi
    fi
done

# =================== DECRYPT  ===================
gpg --pinentry-mode=loopback --decrypt $1 > $(dirname $1)/$secrets
