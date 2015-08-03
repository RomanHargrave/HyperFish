# Hyperjump knockoff for fish

set -gx __fish_hyperjump_db     $HOME/.hyperjumpdb 

function __hj_err 
    echo $argv 1>&2
end 

# Intialize the DB file if needed and return the path to it
function __hj_setupdb
    if not [ -f $__fish_hyperjump_db ]
        echo "home:$HOME" > $__fish_hyperjump_db 
    end 

    echo $__fish_hyperjump_db 
end 

# Uniqify the DB's keyset
function __hj_db_uniq
    sort -fu -k1 -t: (__hj_setupdb)
end 

# List all location names 
function __hj_list_nicks 
    __hj_db_uniq | cut -d: -f1  
end 

# List all location paths
function __hj_list_paths 
    cut -d: -f2- (__hj_setupdb)
end 

# Look for a path in the DB.
# If it exists, return 0 and output the nickname.
# Otherwise non-zero (see grep)
function __hj_find_loc -a path
    grep -Po ".*(?=\Q:$path\E\$)" (__hj_setupdb)
end 

# Look for a path in the DB with a given name
# If such an entry exists, the path for the name is output and zero is returned
# Otherwise non-zero (see grep)
function __hj_find_nick -a nick
    grep -Po "(?<=\Q$nick:\E).*\$" (__hj_setupdb)
end 

# Add an entry to the DB
function __hj_append_loc -a nick path 
    echo "$nick:$path" >> (__hj_setupdb)
end 

# Add a location
# 
# Error values
# 1     No nickname provided
# 2     Location already known
# 3     Nickname already known
function jr 
    # Args 

    ## nick -- required
    if not begin set nick $argv[1]; and set -e argv[1]; end
        __hj_err "A nickname must be given for the location"
        return 1 
    end 
    
    ## path -- optional, defaults to pwd
    set path    $PWD
    if set -q argv[1] 
        set path $argv[1]; and set -e argv[1]
    end 

    # Check for location
    if set exsting_path_nick (__hj_find_loc $path)
        __hj_err "This location is already stored as $existing_path_nick"
        return 2
    end 

    # Check for the nick
    if set existing_nick_path (__hj_find_nick $nick)
        __hj_err "This nickname already exists (points to $existing_nick_path)"
        return 3
    end 

    # All's good -- add it
    __hj_append_loc $nick $path 
end

# Forget a location
#
# Error values
# 1     Could not find anything
# 2     Not removing entry
# *     see `man sed`
function jf 
    # Args
    set implicit_target no 
    set that ''
    if not begin set that $argv[1]; and set -e argv[1]; end
        # Assume $PWD
        set that $PWD
        set implicit_target yes 
    end 

    # Try to find a directory first
    set target_nick that 
    if not set target_nick (__hj_find_loc $that)
        if not __hj_find_nick $that ^/dev/null 
            __hj_err "Could not find an entry with the path or nickname $that"
            return 1

        else if [ $implicit_target == 'yes' ] 
            # Do not remove things with a nickname that could match $PWD (could happen!)
            __hj_err "An entry with the nickname $that exists, but will not be removed since it was not explicitly provided"
            return 2
        end
    end

    # Remove the line starting with target_nick using sed (/g specified _just in case_)
    if not sed -i "/^$target_nick:/d" (__hj_setupdb)
        __hj_err "Could not delete item with name $target_nick: sed returned $status"
        return 3
    end 
end 

# Location jump backend logic
#
# Error values
# 1     Missing parameter
# 2     No location found
# *     See `man cd`
function __jumpto_logic
    # Args
    
    set nick ''
    if not begin set nick $argv[1]; and set -e argv[1]; end 
        __hj_err "A nickname must be provided"
        return 1
    end

    if set location (__hj_find_nick $nick)
        echo $location
    else
        __hj_err "Could not find a location with that nickname"
        return 2
    end 
end

# jump-to frontends

## jj: Use `cd` to go to the location
function jj -a nick
    if set location (__jumpto_logic $nick)
        cd $location
    end 
end 

## jp: Use `pushd` to go to the location
function jp -a nick 
    if set location (__jumpto_logic $nick)
        pushd $location
    end 
end

# List locations
function jl 
    column -s: -t < (__hj_setupdb)
end 

# Completions
begin
    function __hj_complete_nicks -a name 
        complete -f -c $name -d 'Bookmark' -a '(__hj_list_nicks)'
    end 

    function __hj_complete_paths -a name 
        complete -f -c $name -d 'Saved Path' -a '(__hj_list_paths)'
    end 
        
    __hj_complete_nicks     jj
    __hj_complete_nicks     jp 

    __hj_complete_nicks     jf 
    __hj_complete_paths     jf

end 
