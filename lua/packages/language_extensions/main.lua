local assert = assert
local type = type

if (SERVER) then
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
    function language.GetFlag( lang )
        lang = type( lang ) == "string" and lang or language.Get()

        if file_Exists( "resource/localization/" .. lang .. ".png", "GAME" ) then
            return "resource/localization/" .. lang .. ".png"
        end

        if file_Exists( "materials/flags16/" .. lang .. ".png", "GAME" ) then
            return "materials/flags16/" .. lang .. ".png"
        end

        return "materials/flags16/gb.png"
    end
end

local defaultLang = CreateConVar( "default_language", "en", FCVAR_ARCHIVE, " - Default language of Garry's mod" ):GetString()
local defaultFlag = language.GetFlag( defaultLang )

do

    local countryNames = {}
    game_ready.wait( http.Fetch, "https://raw.githubusercontent.com/fannarsh/country-list/master/data.json", function( body, size, headers, code )
        if (code == 200) then
            local tbl = util.JSONToTable( body )
            if (tbl) then

                for num, data in ipairs( tbl ) do
                    countryNames[ data.code:lower() ] = data.name
                end

            end
        end
    end)

    function language.GetCountry( lang )
        return countryNames[ lang ] or lang
    end

end

if (SERVER) then

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

local phrases = {["en"] = {}}
function language.GetStored()
    return phrases
end

local startup_language = language.Get()
if (phrases[ startup_language ] == nil) then
    phrases[ startup_language ] = {}
end

game_ready.wait( function()
    hook.Run( "LanguageChanged", "en", startup_language )
end )

local add = environment.saveFunc( "language.Add", language.Add )
function language.Add( placeholder, fulltext, lang )
    assert( type( placeholder ) == "string", "bad argument #1 (string expected)" )
    if type( fulltext ) ~= "string" then
        fulltext = placeholder
    end

    lang = type( lang ) == "string" and lang or language.Get()
    if (phrases[ lang ] == nil) then
        phrases[ lang ] = {}
    end

    phrases[ lang ][ placeholder ] = fulltext

    local langNow = language.Get()
    if (langNow == lang) or (phrases[ langNow ][ placeholder ] == nil) then
        add( placeholder, fulltext )
    end
end

local get = environment.saveFunc( "language.GetPhrase", language.GetPhrase )
function language.GetPhrase( placeholder, lang )
    local langPhrases = phrases[ type( lang ) == "string" and lang or language.Get() ]
    if (langPhrases ~= nil) then
        local phrase = langPhrases[ placeholder ]
        if (phrase ~= nil) then
            return phrase
        end
    end

    return get( placeholder )
end

function language.HasPhrase( placeholder )
    return get( placeholder ) ~= placeholder
end

do

    local scripted_ents_GetStored = scripted_ents.GetStored
    local weapons_GetStored = weapons.GetStored
    local ents_FindByClass = ents.FindByClass
    local list_Set = list.Set
    local list_Get = list.Get
    local tostring = tostring
    local ipairs = ipairs
    local pairs = pairs

    -- Spawnmenu Support
    local spawnmenuTabs = {
        "SpawnableEntities",
        "Vehicles",
        "Weapon",
        "NPC"
    }

    hook.Add("LanguageChanged", "Language Extensions:Update Phrases", function( old, new )

        if ( phrases[ new ] == nil ) then
            return
        end

        -- Update all phrases in game
        for placeholder, fulltext in pairs( phrases[ new ] ) do
            add( placeholder, fulltext )

            local isCategory = placeholder:StartWith("spawnmenu.")
            local categoryName = placeholder:sub( 11, #placeholder ):lower()
            for num, tabName in ipairs( spawnmenuTabs ) do
                for class, tbl in pairs( list_Get( tabName ) ) do
                    if type( tbl ) == "table" then
                        if not isCategory then
                            if (class == placeholder) then

                                -- Weapons
                                if (tabName == spawnmenuTabs[3]) then
                                    local SWEP = weapons_GetStored( placeholder )
                                    if (SWEP ~= nil) then
                                        SWEP.PrintName = "#" .. placeholder
                                    end

                                    for num, ent in ipairs( ents_FindByClass( placeholder ) ) do
                                        local printName = ent:GetPrintName()
                                        if (printName) then
                                            local tranlatedName = get( printName )
                                            if (phrases["en"][ placeholder ] == nil) and (tranlatedName ~= printName) then
                                                phrases["en"][ placeholder ] = tranlatedName
                                            end

                                            if (tranlatedName ~= fulltext) then
                                                add( printName, fulltext )
                                            end
                                        else
                                            ent.PrintName = "#" .. placeholder
                                        end
                                    end

                                    if (phrases["en"][ placeholder ] == nil) then
                                        phrases["en"][ placeholder ] = get( tbl.PrintName )
                                    end
                                end

                                -- Entites
                                if (tabName == spawnmenuTabs[1]) then
                                    if (phrases["en"][ placeholder ] == nil) then
                                        phrases["en"][ placeholder ] = tbl.PrintName or fulltext
                                    end

                                    local ENT = scripted_ents_GetStored( placeholder )
                                    if (ENT ~= nil) then
                                        ENT.PrintName = "#" .. placeholder
                                    end

                                    for num, ent in ipairs( ents_FindByClass( placeholder ) ) do
                                        ent.PrintName = "#" .. placeholder
                                    end
                                end

                                local key = "PrintName"
                                if (tabName == spawnmenuTabs[4]) or (tabName == spawnmenuTabs[2]) then
                                    key = "Name"
                                end

                                if (tbl[key] ~= nil) then
                                    if (phrases["en"][ placeholder ] == nil) then
                                        phrases["en"][ placeholder ] = tbl[ key ]
                                    end

                                    tbl[ key ] = "#" .. placeholder
                                end
                            end
                        -- elseif type(tbl.Category) == "string" and (tbl.Category:lower() == categoryName) then
                        --     if (phrases["en"][ placeholder ] == nil) then
                        --         phrases["en"][ placeholder ] = tbl.Category or "Other"
                        --     end

                        --     tbl.Category = "#" .. placeholder
                        end

                        list_Set( tabName, class, tbl )
                    end
                end
            end

            if (SERVER) and placeholder:StartWith( "game_text." ) then
                for num, ent in ipairs( ents_FindByClass( "game_text" ) ) do
                    if (ent.__message == nil) then
                        ent.__message = tostring( ent:GetKeyValues().message )
                    end

                    local message = ent.__message:Replace( "#", "" )
                    if (message == placeholder) then
                        if (phrases["en"][ placeholder ] == nil) then
                            phrases["en"][ placeholder ] = ent.__message
                        end

                        ent:SetKeyValue( "message", fulltext )
                    end
                end
            end
        end

        if (CLIENT) then
            timer.Simple(0, function()
                if GAMEMODE.IsSandboxDerived then
                    RunConsoleCommand("spawnmenu_reload")
                end
            end)
        end

    end)

end

function language.Remove( placeholder, lang )

    if ( type( lang ) == "string" ) then

        if ( phrases[ lang ] ~= nil ) then
            phrases[ lang ][ placeholder ] = nil
        end

        if ( lang == language.Get() ) then
            language.Add( placeholder, placeholder )
        end

    else

        local langNow = language.Get()
        if ( phrases[ langNow ] ~= nil ) then
            phrases[ langNow ][ placeholder ] = nil
        end

        language.Add( placeholder, placeholder )

    end

end

do
    local pattern = "[^%s]+"
    function language.Translate( fulltext, symbol )
        local hasSymbol = (symbol ~= nil)
        for placeholder in fulltext:gmatch( pattern ) do
            if (hasSymbol) then
                if not placeholder:StartWith( symbol ) or (placeholder == symbol) then
                    continue
                end

                fulltext = fulltext:Replace( placeholder, get( placeholder:sub( #symbol + 1, #placeholder ) ) )
                continue
            end

            fulltext = fulltext:Replace( placeholder, get( placeholder ) )
        end

        return fulltext
    end
end

-- Garry's Mod weapons corrections
language.Add( "weapon_physgun", "PHYSICS GUN", "en" )
language.Add( "manhack_welder", "Manhack Gun", "en" )
language.Add( "weapon_medkit", "Medkit", "en" )
language.Add( "gmod_camera", "Camera", "en" )
language.Add( "weapon_fists", "Fists", "en" )
language.Add( "gmod_tool", "Tool Gun", "en" )