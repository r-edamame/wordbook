
port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Browser
import Debug

port authenticateWithTwitter : () -> Cmd msg

type alias Token = String

main = Browser.document
    { view=view
    , update=update
    , subscriptions=always Sub.none
    , init=init
    }

init : Token -> ((), Cmd ())
init token = (always () <| Debug.log "token: " token, Cmd.none)

update _ _ = ((), authenticateWithTwitter ())

view : () -> Browser.Document ()
view model =
    { title="log in"
    , body=
        [ div []
            [ button [onClick () ] [text "auth" ]
            ]
        ]
    }
