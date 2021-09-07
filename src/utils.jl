
"""parse a single line of space separated integers"""
space_sep_ints(s::AbstractString; base=10) = parse.(Int, split(s); base)


function file_extension(path::String)
    if contains(path, ".")
        return path[findlast(isequal('.'),path):end]
    else
        return ""
    end
end
