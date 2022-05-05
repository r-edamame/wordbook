port module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Memorize
import Create

import Browser
import Browser.Navigation as Nav
import Url exposing (Url)

import Http
import HttpBuilder

import Debug
import Config exposing (..)

port auth : () -> Cmd msg


------------------
-- Main Program --
------------------

init : String -> Url -> Nav.Key -> (Model, Cmd Msg)
init token url key =
    let
        (page, cmd) = case token of
            "" -> (LoginPage, Cmd.none)
            _ -> route token url
        model =
            { page=page
            , key=key
            , token=token
            }
    in (model, cmd)

main = Browser.application
    { init=init
    , view=view
    , update=update
    , subscriptions=subscriptions
    , onUrlRequest=OnUrlRequest
    , onUrlChange=OnUrlChange
    }


----------------------
-- Page Definitions --
----------------------

type Page
    = LoginPage
    | MemorizePage Memorize.Model
    | CreatePage Create.Model
    | NotFoundPage

getTitle : Page -> String
getTitle page = case page of
    LoginPage       -> "Log in"
    MemorizePage _  -> "学習"
    CreatePage _    -> "単語追加"
    NotFoundPage    -> "Not Found"
    
type Route
    = Memorize
    | Create

routeToString : Route -> String
routeToString rt = case rt of
    Memorize -> "/#memorize"
    Create -> "/#create"

route : String -> Url -> (Page, Cmd Msg)
route token url = case url.fragment of
    Nothing -> Tuple.mapBoth MemorizePage (Cmd.map MemorizeMsg) (Memorize.init token)
    Just "memorize" -> Tuple.mapBoth MemorizePage (Cmd.map MemorizeMsg) (Memorize.init token)
    Just "create" ->   Tuple.mapBoth CreatePage (Cmd.map CreateMsg) (Create.init token)
    _ ->          (NotFoundPage, Cmd.none)

type alias Model =
    { page : Page
    , key : Nav.Key
    , token : String
    }

type Msg
    = Auth
    | OnUrlRequest Browser.UrlRequest
    | OnUrlChange Url
    | MemorizeMsg Memorize.Msg
    | CreateMsg Create.Msg
    | AuthSucceeded
    | AuthFailed

-------------------
-- TEA functions --
-------------------

update : Msg -> Model -> (Model, Cmd Msg)
update msg_ model = case (model.page, msg_) of
    (LoginPage, Auth) -> (model, auth ())
    (_, OnUrlRequest req) -> case req of
        Browser.Internal url -> (model, Nav.pushUrl model.key <| Url.toString url)
        Browser.External url -> (model, Cmd.none)
    (_, OnUrlChange url) ->
        let (page, cmd) = route model.token url
        in ({model| page=page}, cmd)

    --Each Page Update
    (MemorizePage memorize, MemorizeMsg msg) ->
        let (updated, cmd) = Memorize.update msg memorize
        in ({model| page=MemorizePage updated}, Cmd.map MemorizeMsg cmd)
    (CreatePage create, CreateMsg msg) ->
        let (updated, cmd) = Create.update msg create
        in ({model| page=CreatePage updated}, Cmd.map CreateMsg cmd)

    -- Auth Checking
    (_, AuthFailed) -> ({model| page=LoginPage}, Cmd.none)
    (_, AuthSucceeded) -> (model, Cmd.none)

    -- Invalid Meg
    (_,_) -> (model, Cmd.none)

subscriptions : Model -> Sub Msg
subscriptions = always Sub.none

view : Model -> Browser.Document Msg
view model =
    let
        contents = case model.page of
            MemorizePage memorize ->
                Html.map MemorizeMsg <| Memorize.view memorize
            CreatePage create ->
                Html.map CreateMsg <| Create.view create
            LoginPage -> viewLogin
            NotFoundPage -> viewNotFound
    in
        { title = getTitle model.page
        , body =
            [ viewHeader
            , viewContents contents
            ]
        }

viewHeader : Html Msg
viewHeader =
    header []
        [ a [ href "/" ] [ text "単語帳" ]
        ]

viewContents : Html Msg -> Html Msg
viewContents contents =
    div [ class "content-wrapper" ]
     [ contents ]

viewMenu : Html Msg
viewMenu =
    div []
        [ div []
            [ a [ href (routeToString Memorize) ] [ text "学習ページ" ]
            ]
        , div []
            [ a [ href (routeToString Create) ] [ text "単語登録" ]
            ]
        ]

viewNotFound : Html msg
viewNotFound =
    div [ class "notfound" ]
        [ text "page not found"
        , a [ href "/" ] [ text "home" ]
        ]

viewLogin : Html Msg
viewLogin =
    div [ class "auth" ]
        [ div []
            [ text "認証してください" ]
        , div [ class "twitter" ]
            [ button [ onClick Auth ] [ text "Twitter認証" ]
            ]
        , viewNotes
        ]

viewNotes : Html Msg
viewNotes =
    ul [ class "note" ]
        [ note "現在，アカウント削除機能は実装されておりません"
        ]

note content =
    li [ class "content" ] [ text content ]
