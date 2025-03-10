unit CommandCollectionUnit;

interface

type
  TCommandCollection = (
                        ccGetPlayState,
                        ccGetPlayStateReply,
                        ccSetPlayState,
                        ccSetPlayStateReply,
                        ccNextComposition,
                        ccNextCompositionReply,
                        ccPrevComposition,
                        ccPrevCompositionReply,
                        ccSetVolumeUp,
                        ccSetVolumeUpReply,
                        ccSetVolumeDown,
                        ccSetVolumeDownReply
                       );

implementation


end.
