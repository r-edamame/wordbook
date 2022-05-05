
module Type exposing (..)

import Json.Decode as Decode exposing (Decoder)

type alias Sentence =
    { id : String
    , japanese : String
    , english : String
    , group : String
    }


decodeSentence : Decoder Sentence
decodeSentence =
    Decode.map4 Sentence
        (Decode.field "id" <| Decode.string)
        (Decode.field "japanese" <| Decode.string)
        (Decode.field "english" <| Decode.string)
        (Decode.field "group" <| Decode.string)
