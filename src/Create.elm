
module Create exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import Browser
import Json.Encode as Encode
import Json.Decode as Decode exposing (Decoder)
import Http
import HttpBuilder

import Config exposing (..)

import Debug


------------------
-- Main Program --
------------------

init : String -> (Model, Cmd Msg)
init token =
    let
        model =
            { japanese=""
            , english=""
            , group=""
            , status=Waiting
            , successMessage=Nothing
            , errorMessage=Nothing
            , token=token
            }
    in (model, Cmd.none)


----------------------
-- Type Definision ---
----------------------

type Status
    = Submitting
    | Waiting

type alias Model =
    { japanese : String
    , english : String
    , group : String
    , status : Status
    , successMessage : Maybe String
    , errorMessage : Maybe String
    , token : String
    }

type Msg
    = InputJapanese String
    | InputEnglish String
    | InputGroup String
    | Submit
    | RecieveOk
    | RecieveError String


-------------------
-- HTTP Requests --
-------------------

errToMsg : (String -> Msg) -> Http.Error -> Msg
errToMsg toMsg error = case error of
    Http.BadUrl _ -> toMsg "bad url"
    Http.Timeout -> toMsg "timeout"
    Http.NetworkError -> toMsg "network error"
    Http.BadStatus status -> toMsg <| "bad status: " ++ String.fromInt status
    Http.BadBody body -> toMsg <| "bad body: " ++ body

type alias ResponseError = String

decodeResponse : Decoder a -> Decoder (Result ResponseError a)
decodeResponse contentDecoder =
    Decode.field "status" Decode.string
        |> Decode.andThen (\status -> case status of
            "ok" -> Decode.map Ok (Decode.field "content" contentDecoder)
            "error" -> Decode.map Err (Decode.field "message" Decode.string)
            _ -> Decode.fail "invalid json response")

postNewQuestion : Model -> Cmd Msg
postNewQuestion model =
    let
        json = Encode.object
            [ ("japanese", Encode.string model.japanese)
            , ("english", Encode.string model.english)
            , ("group", Encode.string model.group)
            ]
        handle res = case res of
            Ok ok -> case ok of
                Ok _ -> RecieveOk
                Err mes -> RecieveError mes
            Err err -> errToMsg RecieveError err
        endpoint = apiHost ++ createPath
    in
        HttpBuilder.post endpoint
            |> HttpBuilder.withJsonBody json
            |> HttpBuilder.withExpect (Http.expectJson handle <| decodeResponse (Decode.null ()))
            |> HttpBuilder.withHeader "Authorization" ("Bearer " ++ model.token)
            |> HttpBuilder.request

-------------------
-- TEA Functions --
-------------------

reset : Model -> Model
reset model = {model| errorMessage = Nothing, successMessage = Nothing}

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
    InputJapanese japanese -> ({model|japanese=japanese}, Cmd.none)
    InputEnglish english -> ({model| english=english}, Cmd.none)
    InputGroup group -> ({model| group=group}, Cmd.none)
    Submit -> (reset {model| status=Submitting}, postNewQuestion model)
    RecieveOk -> ({model| status=Waiting, japanese="", english="", successMessage=Just "追加されました"}, Cmd.none)
    RecieveError error -> ({model| errorMessage=Just error, status=Waiting}, Cmd.none)

view : Model -> Html Msg
view model =
    div []
        [ viewDescription
        , viewContent model
        ]

viewDescription : Html Msg
viewDescription =
    div [ class "menu-title" ]
        [ text "単語の追加"]

viewContent : Model -> Html Msg
viewContent model =
    div [ class "create container" ]
        [ div [ class "japanese input-wrapper" ]
            [ div [ class "description" ]
                [ text "日本語" ]
            , div [ class "input" ]
                [ input [ onInput InputJapanese, value model.japanese ]
                    []
                ]
            ]
        , div [ class "english input-wrapper" ]
            [ div [ class "description" ]
                [ text "英語" ]
            , div [ class "input" ]
                [ input [ onInput InputEnglish, value model.english ]
                    []
                ]
            ]
        , div [ class "group input-wrapper" ]
            [ div [ class "description" ]
                [ text "グループ" ]
            , div [ class "input" ]
                [ input [ onInput InputGroup ]
                    []
                ]
            ]
        , div [ class "submit" ]
            [ div [ class "button-wrapper" ]
                [ button [ onClick Submit, disabled (model.status==Submitting) ] [ text "追加" ]
                ]
            ]
        , case model.successMessage of
            Nothing -> text ""
            Just mes ->
                div [ class "success-message" ]
                    [ text mes
                    ]
        , case model.errorMessage of
            Nothing -> text ""
            Just mes ->
                div [ class "error-message" ]
                    [ text mes
                    ]
        ]
