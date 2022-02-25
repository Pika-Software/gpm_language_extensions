local assert = assert
local type = type

if SERVER then
    module( "language", package.seeall )

    local phrases = {}
    function Add( placeholder, fulltext )
        assert( type( placeholder ) == "string", "bad argument #1 (string expected)" )
        assert( type( fulltext ) == "string", "bad argument #2 (string expected)" )
        phrases[ placeholder ] = fulltext
    end

    function GetPhrase( placeholder )
        assert( type( placeholder ) == "string", "bad argument #1 (string expected)" )
        return phrases[ placeholder ] or placeholder
    end
end

do
    local file_Exists = file.Exists
    function language.Exists( lang )
        assert( type( lang ) == "string", "bad argument #1 (string expected)" )
        return file_Exists( "materials/flags16/" .. lang .. ".png", "GAME" )
    end
end

local defaultLang = "gb"
local defaultFlag = "materials/flags16/" .. defaultLang .. ".png"

function language.GetFlag( lang )
    lang = type( lang ) == "string" and lang or language.Get()
    return language.Exists( lang ) and "materials/flags16/" .. lang .. ".png" or defaultFlag
end

if SERVER then

    local serverLanguage = CreateConVar( "sv_language", defaultLang, FCVAR_ARCHIVE, " - Changes language of Garry's mod" ):GetString()

    do
        local RunConsoleCommand = RunConsoleCommand
        local hook_Run = hook.Run

        if ( serverLanguage == "" ) then
            serverLanguage = defaultLang
            RunConsoleCommand( "sv_language", defaultLang )
        end

        cvars.AddChangeCallback("sv_language", function( name, old, new )
            if ( hook_Run( "LanguageChanged", old, new ) == true ) then
                return
            end

            if ( new == "" ) then
                RunConsoleCommand( "sv_language", defaultLang )
            else
                serverLanguage = new
            end
        end, "Language Extensions:sv_language")
    end

    function language.Get()
        return serverLanguage
    end

else

    local playerLanguage = GetConVar( "gmod_language" ):GetString()

    do
        local RunConsoleCommand = RunConsoleCommand
        local hook_Run = hook.Run

        if ( playerLanguage == "" ) then
            playerLanguage = defaultLang
            RunConsoleCommand( "gmod_language", defaultLang )
        end

        cvars.AddChangeCallback("gmod_language", function( name, old, new )
            if ( hook_Run( "LanguageChanged", old, new ) == true ) then
                return
            end

            if ( new == "" ) then
                RunConsoleCommand( "gmod_language", defaultLang )
            else
                serverLanguage = new
            end
        end, "Language Extensions:gmod_language")
    end

    function language.Get()
        return playerLanguage or defaultLang
    end

end

local phrases = {}

local add = environment.saveFunc( "language.Add", language.Add )
function language.Add( placeholder, fulltext, lang )
    assert( type( placeholder ) == "string", "bad argument #1 (string expected)" )
    assert( type( fulltext ) == "string", "bad argument #2 (string expected)" )

    if (phrases[ lang ] == nil) then
        phrases[ lang ] = {}
    end

    phrases[ lang ][ placeholder ] = fulltext

    local langNow = language.Get()
    if ( langNow == lang ) or ( phrases[ langNow ][ placeholder ] == nil ) then
        add( placeholder, fulltext )
    end
end

hook.Add("LanguageChanged", "Language Extensions:Update Phrases", function( old, new )

    if (phrases[ new ] != nil) then
        for placeholder, fulltext in pairs( phrases[ new ] ) do
            add( placeholder, fulltext )
        end
    end

end)

function language.Remove( placeholder, lang )

    local langNow = language.Get()
    if type( lang ) != "string" then

        phrases[ langNow ][ placeholder ] = nil
        language.Add( placeholder, placeholder )

    else

        if ( phrases[ lang ] != nil ) then
            phrases[ lang ][ placeholder ] = nil
        end

        if ( lang == langNow ) then
            language.Add( placeholder, placeholder )
        end

    end

end