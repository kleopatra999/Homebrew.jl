# This file contains all functions that either do not directly interface with `brew`
# or peek into the internals of Homebrew a bit, such as `install_brew()` which
# installs Homebrew using Git, `tap_exists()` which presupposes knowledge of the
# internal layout of Taps, and `installed()` which presupposed knowledge of the
# location of files within the Cellar

const tappath = joinpath(brew_prefix,"Library","Taps","staticfloat","homebrew-juliadeps")
const BREW_URL = "https://github.com/Homebrew/brew"
const BREW_BRANCH = "master"
const BOTTLE_SERVER = "https://juliabottles.s3.amazonaws.com"


"""
download_and_unpack(url::String, target_dir::String)

Download a tarball from `url` and unpack it into `target_dir`.
"""
function download_and_unpack(url::String, target_dir::String; strip=0)
    @compat run(pipeline(`curl -# -L $url`,
                         `tar xz -m --strip 1 -C $target_dir`))
end

"""
install_brew()

Ensures that Homebrew is installed as desired, that our basic Taps are available
and that we have whatever binary tools we need, such as `install_name_tool`
"""
function install_brew()
    # Ensure brew_prefix exists
    if !isdir(brew_prefix)
        mkdir(brew_prefix)

        try
            Base.info("Downloading brew...")
            @compat run(pipeline(`curl -# -L $BREW_URL/tarball/$BREW_BRANCH`,
                                 `tar xz -m --strip 1 -C $brew_prefix`))
        catch
            warn("Could not download/extract $BREW_URL/tarball/$BREW_BRANCH into $(brew_prefix)!")
            rethrow()
        end
    end

    # Tap homebrew/core, always and forever
    tap("homebrew/core")

    # Tap our own "overrides" tap
    tap("staticfloat/juliadeps")

    # Add cctools and force-link it
end

"""
tap_overrides(name::String; tap_path::String=tappath)

Check to see if a tap (defaults to the staticfloat/juliadeps tap) overrides the
given package name, returning true if it is overridden.
"""
function tap_overrides(name::String; tap_path::String = tappath)
    cd(tap_path) do
        return isfile("$name.rb")
    end
end

"""
tap_overrides(pkg::BrewPkg; tap_path::String=tappath)

Check to see if a tap (defaults to the staticfloat/juliadeps tap) overrides the
given package name, returning true if it is overridden.
"""
function tap_overrides(pkg::BrewPkg; tap_path::String = tappath)
    return tap_overrides(pkg.name; tap_path = tap_path)
end

"""
tap_exists(tap_name::String)

Check to see if a certain tap exists
"""
function tap_exists(tap_name::String)
    path = joinpath(brew_prefix,"Library","Taps", dirname(tap_name), "homebrew-$(basename(tap_name))")
    return isdir(path)
end


"""
installed(name::String)

Return true if the given package `name` is a directory in the Cellar, showing
that is has been installed (but possibly not linked, see `linked()`)
"""
function installed(name::String)
    isdir(joinpath(brew_prefix,"Cellar",name))
end

"""
installed(pkg::BrewPkg)

Return true if the given package `pkg` is a directory in the Cellar, showing
that is has been installed (but possibly not linked, see `linked()`)
"""
function installed(pkg::BrewPkg)
    installed(pkg.name)
end

"""
linked(name::String)

Returns true if the given package `name` is linked to LinkedKegs, signifying
all files installed by this package have been linked into the global prefix.
"""
function linked(name::String)
    return islink(joinpath(brew_prefix,"Library","LinkedKegs",name))
end

"""
linked(pkg::BrewPkg)

Returns true if the given package `pkg` is linked to LinkedKegs, signifying
all files installed by this package have been linked into the global prefix.
"""
function linked(pkg::BrewPkg)
    return linked(pkg.name)
end