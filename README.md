# gpm_language_extensions
 A set of features and changes targeted at improving and speeding up the language library.

## Functions:

### `string` language.Get()
`Returns current language.`

### language.Add( `string` placeholder, `string` fulltext, `string` lang )
`Adds a language item. Language placeholders preceded with "#" are replaced with full text in Garry's Mod once registered with this function.`

### language.Remove( `string` placeholder, `string` lang )
`Removes a phrase from a language.`

### `string` language.GetPhrase( `string` phrase )
`Retrieves the translated version of inputted string. Useful for concentrating multiple translated strings.`

### `string` language.GetFlag( `string` lang )
`Returns the path to the language flag material.`

### `boolean` language.Exists( `string` lang )
`Lets you know if a language flag exists.`

## Hooks:

### `LanguageChanged` - function( `string` oldLang, `string` newLang )
`Called when language is changed and returns old language and new language.`

## Convars:

### `default_language` (def. `"gb"`) - Default language of Garry's mod.
### `sv_language` (def. `default_language`) - Changes language of Garry's mod on server.
### `gmod_language` (def. `default_language`) - Changes language of Garry's mod on client.
