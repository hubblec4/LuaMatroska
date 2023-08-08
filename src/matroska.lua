-- Matroska library for reading Matroska files
-- written by hubblec4


--[=[ Lua Verison compatiblity: 
    Lua 5.1, Lua 5.2 and LuaJIT are not able to handle Bit operations fully
    Lua 5.3 (and higher, 5.3++) has proper build-in Bit operation support  
    
    I use my own "Compiler switch" technic to support both cases directly
    Code for Lua5.3++ uses: --[[LuaNew <- start switch
    Code for older Lua versions uses: -- [[LuaOld <- start switch
    for switching you have to make a manual String replace
    Xxx = "New" or "Old"
    activate LuaXxx: change "--[[LuaXxx" to "-- [[LuaXxx"
    disable LuaXxx: change "-- [[LuaXxx" to "--[[LuaXxx"    

    default version is LuaOld
--]=]



local ebml = require "ebml"

local Segment = ebml.master:new()


local seekhead = {
    SeekHead = ebml.master:new(),
    Seek = ebml.master:new(),
    SeekID = ebml.binary:new(),
    SeekPosition = ebml.uinteger:new()
}


local info = {
    Info = ebml.master:new(),
    SegmentUUID = ebml.binary:new(),
    SegmentFilename = ebml.utf8:new(),
    PrevUUID = ebml.binary:new(),
    PrevFilename = ebml.utf8:new(),
    NextUUID = ebml.binary:new(),
    NextFilename = ebml.utf8:new(),
    SegmentFamily = ebml.binary:new(),
    ChapterTranslate = ebml.master:new(),
    ChapterTranslateID = ebml.binary:new(),
    ChapterTranslateCodec = ebml.uinteger:new(),
    ChapterTranslateEditionUID = ebml.uinteger:new(),
    TimestampScale = ebml.uinteger:new(1000000),
    Duration = ebml.float:new(),
    DateUTC = ebml.date:new(),
    Title = ebml.utf8:new(),
    MuxingApp = ebml.utf8:new(),
    WritingApp = ebml.utf8:new()
}

local cluster = {
    Cluster = ebml.master:new(),
    Timestamp = ebml.uinteger:new(),
    SilentTracks = ebml.master:new(),
    SilentTrackNumber = ebml.uinteger:new(),
    Position = ebml.uinteger:new(),
    PrevSize = ebml.uinteger:new(),
    SimpleBlock = ebml.binary:new(),
    BlockGroup = ebml.master:new(),
    Block = ebml.binary:new(),
    BlockVirtual = ebml.binary:new(),
    BlockAdditions = ebml.master:new(),
    BlockMore = ebml.master:new(),
    BlockAdditional = ebml.binary:new(),
    BlockAddID = ebml.uinteger:new(1),
    BlockDuration = ebml.uinteger:new(),
    ReferencePriority = ebml.uinteger:new(0),
    ReferenceBlock = ebml.integer:new(),
    ReferenceVirtual = ebml.integer:new(),
    CodecState = ebml.binary:new(),
    DiscardPadding = ebml.integer:new(),
    Slices = ebml.master:new(),
    TimeSlice = ebml.master:new(),
    LaceNumber = ebml.uinteger:new(),
    FrameNumber = ebml.uinteger:new(0),
    BlockAdditionID = ebml.uinteger:new(0),
    Delay = ebml.uinteger:new(0),
    SliceDuration = ebml.uinteger:new(0),
    ReferenceFrame = ebml.master:new(),
    ReferenceOffset = ebml.uinteger:new(),
    ReferenceTimestamp = ebml.uinteger:new(),
    EncryptedBlock = ebml.binary:new()
}

local tracks = {
    Tracks = ebml.master:new(),
    TrackEntry = ebml.master:new(),
    TrackNumber = ebml.uinteger:new(),
    TrackUID = ebml.uinteger:new(),
    TrackType = ebml.uinteger:new(),
    FlagEnabled = ebml.uinteger:new(1),
    FlagDefault = ebml.uinteger:new(1),
    FlagForced = ebml.uinteger:new(0),
    FlagHearingImpaired = ebml.uinteger:new(),
    FlagVisualImpaired = ebml.uinteger:new(),
    FlagTextDescriptions = ebml.uinteger:new(),
    FlagOriginal = ebml.uinteger:new(),
    FlagCommentary = ebml.uinteger:new(),
    FlagLacing = ebml.uinteger:new(1),
    MinCache = ebml.uinteger:new(0),
    MaxCache = ebml.uinteger:new(),
    DefaultDuration = ebml.uinteger:new(),
    DefaultDecodedFieldDuration = ebml.uinteger:new(),
    TrackTimestampScale = ebml.float:new(1.0),
    TrackOffset = ebml.integer:new(0),
    MaxBlockAdditionID = ebml.uinteger:new(0),
    BlockAdditionMapping = ebml.master:new(),
    BlockAddIDValue = ebml.uinteger:new(),
    BlockAddIDName = ebml.string:new(),
    BlockAddIDType = ebml.uinteger:new(0),
    BlockAddIDExtraData = ebml.binary:new(),
    Name = ebml.utf8:new(),
    Language = ebml.string:new("eng"),
    LanguageBCP47 = ebml.string:new(),
    CodecID = ebml.string:new(),
    CodecPrivate = ebml.binary:new(),
    CodecName = ebml.utf8:new(),
    AttachmentLink = ebml.uinteger:new(),
    CodecSettings = ebml.utf8:new(),
    CodecInfoURL = ebml.string:new(),
    CodecDownloadURL = ebml.string:new(),
    CodecDecodeAll = ebml.uinteger:new(1),
    TrackOverlay = ebml.uinteger:new(),
    CodecDelay = ebml.uinteger:new(0),
    SeekPreRoll = ebml.uinteger:new(0),
    TrackTranslate = ebml.master:new(),
    TrackTranslateTrackID = ebml.binary:new(),
    TrackTranslateCodec = ebml.uinteger:new(),
    TrackTranslateEditionUID = ebml.uinteger:new(),
    Video = ebml.master:new(),
    FlagInterlaced = ebml.uinteger:new(0),
    FieldOrder = ebml.uinteger:new(2),
    StereoMode = ebml.uinteger:new(0),
    AlphaMode = ebml.uinteger:new(0),
    OldStereoMode = ebml.uinteger:new(),
    PixelWidth = ebml.uinteger:new(),
    PixelHeight = ebml.uinteger:new(),
    PixelCropBottom = ebml.uinteger:new(0),
    PixelCropTop = ebml.uinteger:new(0),
    PixelCropLeft = ebml.uinteger:new(0),
    PixelCropRight = ebml.uinteger:new(0),
    DisplayWidth = ebml.uinteger:new(),
    DisplayHeight = ebml.uinteger:new(),
    DisplayUnit = ebml.uinteger:new(0),
    AspectRatioType = ebml.uinteger:new(0),
    UncompressedFourCC = ebml.binary:new(),
    GammaValue = ebml.float:new(),
    FrameRate = ebml.float:new(),
    Colour = ebml.master:new(),
    MatrixCoefficients = ebml.uinteger:new(2),
    BitsPerChannel = ebml.uinteger:new(0),
    ChromaSubsamplingHorz = ebml.uinteger:new(),
    ChromaSubsamplingVert = ebml.uinteger:new(),
    CbSubsamplingHorz = ebml.uinteger:new(),
    CbSubsamplingVert = ebml.uinteger:new(),
    ChromaSitingHorz = ebml.uinteger:new(0),
    ChromaSitingVert = ebml.uinteger:new(0),
    Range = ebml.uinteger:new(0),
    TransferCharacteristics = ebml.uinteger:new(2),
    Primaries = ebml.uinteger:new(2),
    MaxCLL = ebml.uinteger:new(),
    MaxFALL = ebml.uinteger:new(),
    MasteringMetadata = ebml.master:new(),
    PrimaryRChromaticityX = ebml.float:new(),
    PrimaryRChromaticityY = ebml.float:new(),
    PrimaryGChromaticityX = ebml.float:new(),
    PrimaryGChromaticityY = ebml.float:new(),
    PrimaryBChromaticityX = ebml.float:new(),
    PrimaryBChromaticityY = ebml.float:new(),
    WhitePointChromaticityX = ebml.float:new(),
    WhitePointChromaticityY = ebml.float:new(),
    LuminanceMax = ebml.float:new(),
    LuminanceMin = ebml.float:new(),
    Projection = ebml.master:new(),
    ProjectionType = ebml.uinteger:new(0),
    ProjectionPrivate = ebml.binary:new(),
    ProjectionPoseYaw = ebml.float:new(0.0),
    ProjectionPosePitch = ebml.float:new(0.0),
    ProjectionPoseRoll = ebml.float:new(0.0),
    Audio = ebml.master:new(),
    SamplingFrequency = ebml.float:new(8000),
    OutputSamplingFrequency = ebml.float:new(),
    Channels = ebml.uinteger:new(1),
    ChannelPositions = ebml.binary:new(),
    BitDepth = ebml.uinteger:new(),
    Emphasis = ebml.uinteger:new(0),
    TrackOperation = ebml.master:new(),
    TrackCombinePlanes = ebml.master:new(),
    TrackPlane = ebml.master:new(),
    TrackPlaneUID = ebml.uinteger:new(),
    TrackPlaneType = ebml.uinteger:new(),
    TrackJoinBlocks = ebml.master:new(),
    TrackJoinUID = ebml.uinteger:new(),
    TrickTrackUID = ebml.uinteger:new(),
    TrickTrackSegmentUID = ebml.binary:new(),
    TrickTrackFlag = ebml.uinteger:new(0),
    TrickMasterTrackUID = ebml.uinteger:new(),
    TrickMasterTrackSegmentUID = ebml.binary:new(),
    ContentEncodings = ebml.master:new(),
    ContentEncoding = ebml.master:new(),
    ContentEncodingOrder = ebml.uinteger:new(0),
    ContentEncodingScope = ebml.uinteger:new(1),
    ContentEncodingType = ebml.uinteger:new(0),
    ContentCompression = ebml.master:new(),
    ContentCompAlgo = ebml.uinteger:new(0),
    ContentCompSettings = ebml.binary:new(),
    ContentEncryption = ebml.master:new(),
    ContentEncAlgo = ebml.uinteger:new(0),
    ContentEncKeyID = ebml.binary:new(),
    ContentEncAESSettings = ebml.master:new(),
    AESSettingsCipherMode = ebml.uinteger:new(),
    ContentSignature = ebml.binary:new(),
    ContentSigKeyID = ebml.binary:new(),
    ContentSigAlgo = ebml.uinteger:new(0),
    ContentSigHashAlgo = ebml.uinteger:new(0)
}

local cues = {
    Cues = ebml.master:new(),
    CuePoint = ebml.master:new(),
    CueTime = ebml.uinteger:new(),
    CueTrackPositions = ebml.master:new(),
    CueTrack = ebml.uinteger:new(),
    CueClusterPosition = ebml.uinteger:new(),
    CueRelativePosition = ebml.uinteger:new(),
    CueDuration = ebml.uinteger:new(),
    CueBlockNumber = ebml.uinteger:new(),
    CueCodecState = ebml.uinteger:new(0),
    CueReference = ebml.master:new(),
    CueRefTime = ebml.uinteger:new(),
    CueRefCluster = ebml.uinteger:new(),
    CueRefNumber = ebml.uinteger:new(1),
    CueRefCodecState = ebml.uinteger:new(0)
}

local attachments = {
    Attachments = ebml.master:new(),
    AttachedFile = ebml.master:new(),
    FileDescription = ebml.utf8:new(),
    FileName = ebml.utf8:new(),
    FileMediaType = ebml.string:new(),
    FileData = ebml.binary:new(),
    FileUID = ebml.uinteger:new(),
    FileReferral = ebml.binary:new(),
    FileUsedStartTime = ebml.uinteger:new(),
    FileUsedEndTime = ebml.uinteger:new()
}

local chapters = {
    Chapters = ebml.master:new(),
    EditionEntry = ebml.master:new(),
    EditionUID = ebml.uinteger:new(),
    EditionFlagHidden = ebml.uinteger:new(0),
    EditionFlagDefault = ebml.uinteger:new(0),
    EditionFlagOrdered = ebml.uinteger:new(0),
    EditionDisplay = ebml.master:new(),
    EditionString = ebml.utf8:new(),
    EditionLanguageIETF = ebml.string:new(),
    ChapterAtom = ebml.master:new(),
    ChapterUID = ebml.uinteger:new(),
    ChapterStringUID = ebml.utf8:new(),
    ChapterTimeStart = ebml.uinteger:new(),
    ChapterTimeEnd = ebml.uinteger:new(),
    ChapterFlagHidden = ebml.uinteger:new(0),
    ChapterFlagEnabled = ebml.uinteger:new(1),
    ChapterSegmentUUID = ebml.binary:new(),
    ChapterSkipType = ebml.uinteger:new(),
    ChapterSegmentEditionUID = ebml.uinteger:new(),
    ChapterPhysicalEquiv = ebml.uinteger:new(),
    ChapterTrack = ebml.master:new(),
    ChapterTrackUID = ebml.uinteger:new(),
    ChapterDisplay = ebml.master:new(),
    ChapString = ebml.utf8:new(),
    ChapLanguage = ebml.string:new("eng"),
    ChapLanguageBCP47 = ebml.string:new(),
    ChapCountry = ebml.string:new(),
    ChapProcess = ebml.master:new(),
    ChapProcessCodecID = ebml.uinteger:new(0),
    ChapProcessPrivate = ebml.binary:new(),
    ChapProcessCommand = ebml.master:new(),
    ChapProcessTime = ebml.uinteger:new(),
    ChapProcessData = ebml.binary:new()
}

local tags = {
    Tags = ebml.master:new(),
    Tag = ebml.master:new(),
    Targets = ebml.master:new(),
    TargetTypeValue = ebml.uinteger:new(50),
    TargetType = ebml.string:new(),
    TagTrackUID = ebml.uinteger:new(0),
    TagEditionUID = ebml.uinteger:new(0),
    TagChapterUID = ebml.uinteger:new(0),
    TagAttachmentUID = ebml.uinteger:new(0),
    SimpleTag = ebml.master:new(),
    TagName = ebml.utf8:new(),
    TagLanguage = ebml.string:new("und"),
    TagLanguageBCP47 = ebml.string:new(),
    TagDefault = ebml.uinteger:new(1),
    TagDefaultBogus = ebml.uinteger:new(1),
    TagString = ebml.utf8:new(),
    TagBinary = ebml.binary:new(),
}



-- -----------------------------------------------------------------------------
-- Define Matroska elements ----------------------------------------------------
-- -----------------------------------------------------------------------------

-- Segment ---------------------------------------------------------------------
function Segment:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function Segment:get_context()
    return {id = 0x18538067, manda = true, parent = nil}
end

function Segment:get_semantic()
    return {seekhead.SeekHead, info.Info, cluster.Cluster, tracks.Tracks,
        cues.Cues, attachments.Attachments, chapters.Chapters, tags.Tags}
end

function Segment:get_global_position(relativ_pos)
    return self.data_position + relativ_pos
end

function Segment:unknown_size_is_allowed() return true end
-- -----------------------------------------------------------------------------


-- SeekHead --------------------------------------------------------------------
function seekhead.SeekHead:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function seekhead.SeekHead:get_context()
    return {id = 0x114D9B74, manda = false, parent = Segment}
end

function seekhead.SeekHead:get_semantic()
    return {seekhead.Seek}
end

function seekhead.SeekHead:find_first_of(id_or_elem_class)
    -- returns the Seek element if the id matches the Ebml ID
    local id
    if type(id_or_elem_class) == "number" then
        id = id_or_elem_class
    else
        id = id_or_elem_class:get_context().id
    end

    local seek, i = self:get_child(seekhead.Seek)
    while seek do
        if seek:is_ebml_id(id) then
            return seek, i
        end
        seek, i = self:find_next_child(i)
    end
    return nil, -1
end

-- function seekhead.SeekHead:find_next_of(prev_index)
-- -----------------------------------------------------------------------------


-- Seek ------------------------------------------------------------------------
function seekhead.Seek:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function seekhead.Seek:get_context()
    return {id = 0x4DBB, manda = true, parent = seekhead.SeekHead}
end

function seekhead.Seek:get_semantic()
    return {seekhead.SeekID, seekhead.SeekPosition}
end

function seekhead.Seek:location()
    -- returns the relativ position of the element in the stream
    local seekpos = self:find_child(seekhead.SeekPosition);
    if seekpos then
        return seekpos.value;
    end
    return 0
end

function seekhead.Seek:get_ebml_id()
    local seekid = self:find_child(seekhead.SeekID)
    if seekid then
        local b1, b2, b3, b4 = string.byte(seekid.value, 1, 4)
        -- [[LuaOld
        return math.floor(b1 * 2^24 + b2 * 2^16 + b3 * 2^8 + b4)
        -- LuaOld end ]]
        --[[LuaNew
        return (b1 << 24) + (b2 << 16) + (b3 << 8) + b4
        -- LuaNew end ]]
    end
    return 0
end

function seekhead.Seek:is_ebml_id(id)
    return id == self:get_ebml_id()
end
-- -----------------------------------------------------------------------------


-- SeekID ----------------------------------------------------------------------
function seekhead.SeekID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function seekhead.SeekID:get_context()
    return {id = 0x53AB, manda = true, parent = seekhead.Seek}
end

function seekhead.SeekID:validate_data_size()
    return self.data_size == 4
end
-- -----------------------------------------------------------------------------


-- SeekPosition ----------------------------------------------------------------
function seekhead.SeekPosition:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function seekhead.SeekPosition:get_context()
    return {id = 0x53AC, manda = true, parent = seekhead.Seek}
end
-- -----------------------------------------------------------------------------


-- Info ------------------------------------------------------------------------
function info.Info:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.Info:get_context()
    return {id = 0x1549A966, manda = true, parent = Segment}
end

function info.Info:get_semantic()
    return {info.SegmentUUID, info.SegmentFilename, info.PrevUUID,
        info.PrevFilename, info.NextUUID, info.NextFilename,
        info.SegmentFamily, info.ChapterTranslate, info.TimestampScale,
        info.Duration, info.DateUTC, info.Title, info.MuxingApp,
        info.WritingApp}
end
-- -----------------------------------------------------------------------------


-- SegmentUUID -----------------------------------------------------------------
function info.SegmentUUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.SegmentUUID:get_context()
    return {id = 0x73A4, manda = false, parent = info.Info}
end

function info.SegmentUUID:validate_data_size()
    return self.data_size == 16
end

function info.SegmentUUID:validate_data()
    for v in self.value do
        if string.byte(v, 1) > 0 then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- SegmentFilename -------------------------------------------------------------
function info.SegmentFilename:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.SegmentFilename:get_context()
    return {id = 0x7384, manda = false, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- PrevUUID --------------------------------------------------------------------
function info.PrevUUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.PrevUUID:get_context()
    return {id = 0x3CB923, manda = false, parent = info.Info}
end

function info.PrevUUID:validate_data_size()
    return self.data_size == 16
end
-- -----------------------------------------------------------------------------


-- PrevFilename ----------------------------------------------------------------
function info.PrevFilename:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.PrevFilename:get_context()
    return {id = 0x3C83AB, manda = false, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- NextUUID --------------------------------------------------------------------
function info.NextUUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.NextUUID:get_context()
    return {id = 0x3EB923, manda = false, parent = info.Info}
end

function info.NextUUID:validate_data_size()
    return self.data_size == 16
end
-- -----------------------------------------------------------------------------


-- NextFilename ----------------------------------------------------------------
function info.NextFilename:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.NextFilename:get_context()
    return {id = 0x3E83BB, manda = false, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- SegmentFamily ---------------------------------------------------------------
function info.SegmentFamily:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.SegmentFamily:get_context()
    return {id = 0x4444, manda = false, parent = info.Info}
end

function info.SegmentFamily:validate_data_size()
    return self.data_size == 16
end
-- -----------------------------------------------------------------------------


-- ChapterTranslate ------------------------------------------------------------
function info.ChapterTranslate:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.ChapterTranslate:get_context()
    return {id = 0x6924, manda = false, parent = info.Info}
end

function info.ChapterTranslate:get_semantic()
    return {info.ChapterTranslateID, info.ChapterTranslateCodec,
        info.ChapterTranslateEditionUID}
end
-- -----------------------------------------------------------------------------


-- ChapterTranslateID ----------------------------------------------------------
function info.ChapterTranslateID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.ChapterTranslateID:get_context()
    return {id = 0x69A5, manda = true, parent = info.ChapterTranslate}
end
-- -----------------------------------------------------------------------------


-- ChapterTranslateCodec -------------------------------------------------------
function info.ChapterTranslateCodec:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.ChapterTranslateCodec:get_context()
    return {id = 0x69BF, manda = true, parent = info.ChapterTranslate}
end

function info.ChapterTranslateCodec:validate_data()
    return self.value >= 0 and self.value <= 1
end
-- -----------------------------------------------------------------------------


-- ChapterTranslateEditionUID --------------------------------------------------
function info.ChapterTranslateEditionUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.ChapterTranslateEditionUID:get_context()
    return {id = 0x69FC, manda = false, parent = info.ChapterTranslate}
end
-- -----------------------------------------------------------------------------


-- TimestampScale --------------------------------------------------------------
function info.TimestampScale:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.TimestampScale:get_context()
    return {id = 0x2AD7B1, manda = true, parent = info.Info}
end

function info.TimestampScale:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- Duration --------------------------------------------------------------------
function info.Duration:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.Duration:get_context()
    return {id = 0x4489, manda = false, parent = info.Info}
end

function info.Duration:validate_data()
    return self.value > 0.0
end
-- -----------------------------------------------------------------------------


-- DateUTC ---------------------------------------------------------------------
function info.DateUTC:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.DateUTC:get_context()
    return {id = 0x4461, manda = false, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- Title -----------------------------------------------------------------------
function info.Title:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.Title:get_context()
    return {id = 0x7BA9, manda = false, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- MuxingApp -------------------------------------------------------------------
function info.MuxingApp:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.MuxingApp:get_context()
    return {id = 0x4D80, manda = true, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- WritingApp ------------------------------------------------------------------
function info.WritingApp:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function info.WritingApp:get_context()
    return {id = 0x5741, manda = true, parent = info.Info}
end
-- -----------------------------------------------------------------------------


-- Cluster ---------------------------------------------------------------------
function cluster.Cluster:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.Cluster:get_context()
    return {id = 0x1F43B675, manda = false, parent = Segment}
end

function cluster.Cluster:get_semantic()
    return {cluster.Timestamp, cluster.SilentTracks, cluster.Position,
        cluster.PrevSize, cluster.SimpleBlock, cluster.BlockGroup,
        cluster.EncryptedBlock}
end

function cluster.Cluster:unknown_size_is_allowed() return true end
-- -----------------------------------------------------------------------------


-- Timestamp -------------------------------------------------------------------
function cluster.Timestamp:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.Timestamp:get_context()
    return {id = 0xE7, manda = true, parent = cluster.Cluster}
end
-- -----------------------------------------------------------------------------


-- SilentTracks ----------------------------------------------------------------
function cluster.SilentTracks:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.SilentTracks:get_context()
    return {id = 0x5854, manda = false, parent = cluster.Cluster}
end

function cluster.SilentTracks:get_semantic()
    return {cluster.SilentTrackNumber}
end
-- -----------------------------------------------------------------------------


-- SilentTrackNumber -----------------------------------------------------------
function cluster.SilentTrackNumber:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.SilentTrackNumber:get_context()
    return {id = 0x58D7, manda = false, parent = cluster.SilentTracks}
end
-- -----------------------------------------------------------------------------


-- Position --------------------------------------------------------------------
function cluster.Position:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.Position:get_context()
    return {id = 0xA7, manda = false, parent = cluster.Cluster}
end
-- -----------------------------------------------------------------------------


-- PrevSize --------------------------------------------------------------------
function cluster.PrevSize:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.PrevSize:get_context()
    return {id = 0xAB, manda = false, parent = cluster.Cluster}
end
-- -----------------------------------------------------------------------------


-- SimpleBlock -----------------------------------------------------------------
function cluster.SimpleBlock:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.SimpleBlock:get_context()
    return {id = 0xA3, manda = false, parent = cluster.Cluster}
end
-- -----------------------------------------------------------------------------


-- BlockGroup ------------------------------------------------------------------
function cluster.BlockGroup:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockGroup:get_context()
    return {id = 0xA0, manda = false, parent = cluster.Cluster}
end

function cluster.BlockGroup:get_semantic()
    return {cluster.Block, cluster.BlockVirtual, cluster.BlockAdditions,
        cluster.BlockDuration, cluster.ReferencePriority,
        cluster.ReferenceBlock, cluster.ReferenceVirtual, cluster.CodecState,
        cluster.DiscardPadding, cluster.Slices, cluster.ReferenceFrame}
end
-- -----------------------------------------------------------------------------


-- Block -----------------------------------------------------------------------
function cluster.Block:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.Block:get_context()
    return {id = 0xA1, manda = true, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- BlockVirtual ----------------------------------------------------------------
function cluster.BlockVirtual:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockVirtual:get_context()
    return {id = 0xA2, manda = false, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- BlockAdditions --------------------------------------------------------------
function cluster.BlockAdditions:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockAdditions:get_context()
    return {id = 0x75A1, manda = false, parent = cluster.BlockGroup}
end

function cluster.BlockAdditions:get_semantic()
    return {cluster.BlockMore}
end
-- -----------------------------------------------------------------------------


-- BlockMore -------------------------------------------------------------------
function cluster.BlockMore:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockMore:get_context()
    return {id = 0xA6, manda = true, parent = cluster.BlockAdditions}
end

function cluster.BlockMore:get_semantic()
    return {cluster.BlockAdditional, cluster.BlockAddID}
end
-- -----------------------------------------------------------------------------


-- BlockAdditional -------------------------------------------------------------
function cluster.BlockAdditional:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockAdditional:get_context()
    return {id = 0xA5, manda = true, parent = cluster.BlockMore}
end
-- -----------------------------------------------------------------------------


-- BlockAddID ------------------------------------------------------------------
function cluster.BlockAddID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockAddID:get_context()
    return {id = 0xEE, manda = true, parent = cluster.BlockMore}
end

function cluster.BlockAddID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- BlockDuration ---------------------------------------------------------------
function cluster.BlockDuration:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockDuration:get_context()
    return {id = 0x9B, manda = false, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- ReferencePriority -----------------------------------------------------------
function cluster.ReferencePriority:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.ReferencePriority:get_context()
    return {id = 0xFA, manda = true, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- ReferenceBlock --------------------------------------------------------------
function cluster.ReferenceBlock:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.ReferenceBlock:get_context()
    return {id = 0xFB, manda = false, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- ReferenceVirtual ------------------------------------------------------------
function cluster.ReferenceVirtual:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.ReferenceVirtual:get_context()
    return {id = 0xFD, manda = false, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- CodecState ------------------------------------------------------------------
function cluster.CodecState:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.CodecState:get_context()
    return {id = 0xA4, manda = false, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- DiscardPadding --------------------------------------------------------------
function cluster.DiscardPadding:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.DiscardPadding:get_context()
    return {id = 0x75A2, manda = false, parent = cluster.BlockGroup}
end
-- -----------------------------------------------------------------------------


-- Slices ----------------------------------------------------------------------
function cluster.Slices:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.Slices:get_context()
    return {id = 0x8E, manda = false, parent = cluster.BlockGroup}
end

function cluster.Slices:get_semantic()
    return {cluster.TimeSlice}
end
-- -----------------------------------------------------------------------------


-- TimeSlice -------------------------------------------------------------------
function cluster.TimeSlice:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.TimeSlice:get_context()
    return {id = 0xE8, manda = false, parent = cluster.Slices}
end

function cluster.TimeSlice:get_semantic()
    return {cluster.LaceNumber, cluster.FrameNumber, cluster.BlockAdditionID,
        cluster.Delay, cluster.SliceDuration}
end
-- -----------------------------------------------------------------------------


-- LaceNumber ------------------------------------------------------------------
function cluster.LaceNumber:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.LaceNumber:get_context()
    return {id = 0xCC, manda = false, parent = cluster.TimeSlice}
end
-- -----------------------------------------------------------------------------


-- FrameNumber -----------------------------------------------------------------
function cluster.FrameNumber:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.FrameNumber:get_context()
    return {id = 0xCD, manda = false, parent = cluster.TimeSlice}
end
-- -----------------------------------------------------------------------------


-- BlockAdditionID -------------------------------------------------------------
function cluster.BlockAdditionID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.BlockAdditionID:get_context()
    return {id = 0xCB, manda = false, parent = cluster.TimeSlice}
end
-- -----------------------------------------------------------------------------


-- Delay -----------------------------------------------------------------------
function cluster.Delay:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.Delay:get_context()
    return {id = 0xCE, manda = false, parent = cluster.TimeSlice}
end
-- -----------------------------------------------------------------------------


-- SliceDuration ---------------------------------------------------------------
function cluster.SliceDuration:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.SliceDuration:get_context()
    return {id = 0xCF, manda = false, parent = cluster.TimeSlice}
end
-- -----------------------------------------------------------------------------


-- ReferenceFrame --------------------------------------------------------------
function cluster.ReferenceFrame:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.ReferenceFrame:get_context()
    return {id = 0xC8, manda = false, parent = cluster.BlockGroup}
end

function cluster.ReferenceFrame:get_semantic()
    return {cluster.ReferenceOffset, cluster.ReferenceTimestamp}
end
-- -----------------------------------------------------------------------------


-- ReferenceOffset -------------------------------------------------------------
function cluster.ReferenceOffset:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.ReferenceOffset:get_context()
    return {id = 0xC9, manda = true, parent = cluster.ReferenceFrame}
end
-- -----------------------------------------------------------------------------


-- ReferenceTimestamp ----------------------------------------------------------
function cluster.ReferenceTimestamp:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.ReferenceTimestamp:get_context()
    return {id = 0xCA, manda = true, parent = cluster.ReferenceFrame}
end
-- -----------------------------------------------------------------------------


-- EncryptedBlock --------------------------------------------------------------
function cluster.EncryptedBlock:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cluster.EncryptedBlock:get_context()
    return {id = 0xAF, manda = false, parent = cluster.Cluster}
end
-- -----------------------------------------------------------------------------


-- Tracks ----------------------------------------------------------------------
function tracks.Tracks:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Tracks:get_context()
    return {id = 0x1654AE6B, manda = false, parent = Segment}
end

function tracks.Tracks:get_semantic()
    return {tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- TrackEntry ------------------------------------------------------------------
function tracks.TrackEntry:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackEntry:get_context()
    return {id = 0xAE, manda = true, parent = tracks.Tracks}
end

function tracks.TrackEntry:get_semantic()
    return {tracks.TrackNumber, tracks.TrackUID, tracks.TrackType,
        tracks.FlagEnabled, tracks.FlagDefault, tracks.FlagForced,
        tracks.FlagHearingImpaired, tracks.FlagVisualImpaired,
        tracks.FlagTextDescriptions, tracks.FlagOriginal,
        tracks.FlagCommentary, tracks.FlagLacing, tracks.MinCache,
        tracks.MaxCache, tracks.DefaultDuration,
        tracks.DefaultDecodedFieldDuration, tracks.TrackTimestampScale,
        tracks.TrackOffset, tracks.MaxBlockAdditionID,
        tracks.BlockAdditionMapping, tracks.Name, tracks.Language,
        tracks.LanguageBCP47, tracks.CodecID, tracks.CodecPrivate,
        tracks.CodecName, tracks.AttachmentLink, tracks.CodecSettings,
        tracks.CodecInfoURL, tracks.CodecDownloadURL, tracks.CodecDecodeAll,
        tracks.TrackOverlay, tracks.CodecDelay, tracks.SeekPreRoll,
        tracks.TrackTranslate, tracks.Video, tracks.Audio,
        tracks.TrackOperation, tracks.TrickTrackUID,
        tracks.TrickTrackSegmentUID, tracks.TrickTrackFlag,
        tracks.TrickMasterTrackUID, tracks.TrickMasterTrackSegmentUID,
        tracks.ContentEncodings}
end
-- -----------------------------------------------------------------------------


-- TrackNumber -----------------------------------------------------------------
function tracks.TrackNumber:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackNumber:get_context()
    return {id = 0xD7, manda = true, parent = tracks.TrackEntry}
end

function tracks.TrackNumber:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- TrackUID --------------------------------------------------------------------
function tracks.TrackUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackUID:get_context()
    return {id = 0x73C5, manda = true, parent = tracks.TrackEntry}
end

function tracks.TrackUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- TrackType -------------------------------------------------------------------
function tracks.TrackType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackType:get_context()
    return {id = 0x83, manda = true, parent = tracks.TrackEntry}
end

function tracks.TrackType:validate_data()
    local valid = {1, 2, 3, 16, 17, 18, 32, 33}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- FlagEnabled -----------------------------------------------------------------
function tracks.FlagEnabled:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagEnabled:get_context()
    return {id = 0xB9, manda = true, parent = tracks.TrackEntry}
end

function tracks.FlagEnabled:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagDefault -----------------------------------------------------------------
function tracks.FlagDefault:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagDefault:get_context()
    return {id = 0x88, manda = true, parent = tracks.TrackEntry}
end

function tracks.FlagDefault:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagForced ------------------------------------------------------------------
function tracks.FlagForced:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagForced:get_context()
    return {id = 0x55AA, manda = true, parent = tracks.TrackEntry}
end

function tracks.FlagForced:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagHearingImpaired ---------------------------------------------------------
function tracks.FlagHearingImpaired:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagHearingImpaired:get_context()
    return {id = 0x55AB, manda = false, parent = tracks.TrackEntry}
end

function tracks.FlagHearingImpaired:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagVisualImpaired ----------------------------------------------------------
function tracks.FlagVisualImpaired:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagVisualImpaired:get_context()
    return {id = 0x55AC, manda = false, parent = tracks.TrackEntry}
end

function tracks.FlagVisualImpaired:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagTextDescriptions --------------------------------------------------------
function tracks.FlagTextDescriptions:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagTextDescriptions:get_context()
    return {id = 0x55AD, manda = false, parent = tracks.TrackEntry}
end

function tracks.FlagTextDescriptions:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagOriginal ----------------------------------------------------------------
function tracks.FlagOriginal:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagOriginal:get_context()
    return {id = 0x55AE, manda = false, parent = tracks.TrackEntry}
end

function tracks.FlagOriginal:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagCommentary --------------------------------------------------------------
function tracks.FlagCommentary:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagCommentary:get_context()
    return {id = 0x55AF, manda = false, parent = tracks.TrackEntry}
end

function tracks.FlagCommentary:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- FlagLacing ------------------------------------------------------------------
function tracks.FlagLacing:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagLacing:get_context()
    return {id = 0x9C, manda = true, parent = tracks.TrackEntry}
end

function tracks.FlagLacing:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- MinCache --------------------------------------------------------------------
function tracks.MinCache:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MinCache:get_context()
    return {id = 0x6DE7, manda = true, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- MaxCache --------------------------------------------------------------------
function tracks.MaxCache:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MaxCache:get_context()
    return {id = 0x6DF8, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- DefaultDuration -------------------------------------------------------------
function tracks.DefaultDuration:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.DefaultDuration:get_context()
    return {id = 0x23E383, manda = false, parent = tracks.TrackEntry}
end

function tracks.DefaultDuration:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- DefaultDecodedFieldDuration -------------------------------------------------
function tracks.DefaultDecodedFieldDuration:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.DefaultDecodedFieldDuration:get_context()
    return {id = 0x234E7A, manda = false, parent = tracks.TrackEntry}
end

function tracks.DefaultDecodedFieldDuration:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- TrackTimestampScale ---------------------------------------------------------
function tracks.TrackTimestampScale:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackTimestampScale:get_context()
    return {id = 0x23314F, manda = true, parent = tracks.TrackEntry}
end

function tracks.TrackTimestampScale:validate_data()
    return self.value > 0.0
end
-- -----------------------------------------------------------------------------


-- TrackOffset -----------------------------------------------------------------
function tracks.TrackOffset:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackOffset:get_context()
    return {id = 0x537F, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- MaxBlockAdditionID ----------------------------------------------------------
function tracks.MaxBlockAdditionID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MaxBlockAdditionID:get_context()
    return {id = 0x55EE, manda = true, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- BlockAdditionMapping --------------------------------------------------------
function tracks.BlockAdditionMapping:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BlockAdditionMapping:get_context()
    return {id = 0x41E4, manda = false, parent = tracks.TrackEntry}
end

function tracks.BlockAdditionMapping:get_semantic()
    return {tracks.BlockAddIDValue, tracks.BlockAddIDName,
        tracks.BlockAddIDType, tracks.BlockAddIDExtraData}
end
-- -----------------------------------------------------------------------------


-- BlockAddIDValue -------------------------------------------------------------
function tracks.BlockAddIDValue:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BlockAddIDValue:get_context()
    return {id = 0x41F0, manda = false, parent = tracks.BlockAdditionMapping}
end

function tracks.BlockAddIDValue:validate_data()
    return self.value >= 2
end
-- -----------------------------------------------------------------------------


-- BlockAddIDName --------------------------------------------------------------
function tracks.BlockAddIDName:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BlockAddIDName:get_context()
    return {id = 0x41A4, manda = false, parent = tracks.BlockAdditionMapping}
end
-- -----------------------------------------------------------------------------


-- BlockAddIDType --------------------------------------------------------------
function tracks.BlockAddIDType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BlockAddIDType:get_context()
    return {id = 0x41E7, manda = true, parent = tracks.BlockAdditionMapping}
end
-- -----------------------------------------------------------------------------


-- BlockAddIDExtraData ---------------------------------------------------------
function tracks.BlockAddIDExtraData:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BlockAddIDExtraData:get_context()
    return {id = 0x41ED, manda = false, parent = tracks.BlockAdditionMapping}
end
-- -----------------------------------------------------------------------------


-- Name ------------------------------------------------------------------------
function tracks.Name:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Name:get_context()
    return {id = 0x536E, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- Language --------------------------------------------------------------------
function tracks.Language:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Language:get_context()
    return {id = 0x22B59C, manda = true, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- LanguageBCP47 ---------------------------------------------------------------
function tracks.LanguageBCP47:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.LanguageBCP47:get_context()
    return {id = 0x22B59D, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecID ---------------------------------------------------------------------
function tracks.CodecID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecID:get_context()
    return {id = 0x86, manda = true, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecPrivate ----------------------------------------------------------------
function tracks.CodecPrivate:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecPrivate:get_context()
    return {id = 0x63A2, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecName -------------------------------------------------------------------
function tracks.CodecName:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecName:get_context()
    return {id = 0x258688, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- AttachmentLink --------------------------------------------------------------
function tracks.AttachmentLink:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.AttachmentLink:get_context()
    return {id = 0x7446, manda = false, parent = tracks.TrackEntry}
end

function tracks.AttachmentLink:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- CodecSettings ---------------------------------------------------------------
function tracks.CodecSettings:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecSettings:get_context()
    return {id = 0x3A9697, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecInfoURL ----------------------------------------------------------------
function tracks.CodecInfoURL:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecInfoURL:get_context()
    return {id = 0x3B4040, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecDownloadURL ------------------------------------------------------------
function tracks.CodecDownloadURL:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecDownloadURL:get_context()
    return {id = 0x26B240, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecDecodeAll --------------------------------------------------------------
function tracks.CodecDecodeAll:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecDecodeAll:get_context()
    return {id = 0xAA, manda = true, parent = tracks.TrackEntry}
end

function tracks.CodecDecodeAll:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- TrackOverlay ----------------------------------------------------------------
function tracks.TrackOverlay:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackOverlay:get_context()
    return {id = 0x6FAB, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- CodecDelay ------------------------------------------------------------------
function tracks.CodecDelay:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CodecDelay:get_context()
    return {id = 0x56AA, manda = true, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- SeekPreRoll -----------------------------------------------------------------
function tracks.SeekPreRoll:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.SeekPreRoll:get_context()
    return {id = 0x56BB, manda = true, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- TrackTranslate --------------------------------------------------------------
function tracks.TrackTranslate:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackTranslate:get_context()
    return {id = 0x6624, manda = false, parent = tracks.TrackEntry}
end

function tracks.TrackTranslate:get_semantic()
    return {tracks.TrackTranslateTrackID, tracks.TrackTranslateCodec,
        tracks.TrackTranslateEditionUID}
end
-- -----------------------------------------------------------------------------


-- TrackTranslateTrackID -------------------------------------------------------
function tracks.TrackTranslateTrackID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackTranslateTrackID:get_context()
    return {id = 0x66A5, manda = true, parent = tracks.TrackTranslate}
end
-- -----------------------------------------------------------------------------


-- TrackTranslateCodec ---------------------------------------------------------
function tracks.TrackTranslateCodec:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackTranslateCodec:get_context()
    return {id = 0x66BF, manda = true, parent = tracks.TrackTranslate}
end

function tracks.TrackTranslateCodec:validate_data()
    return self.value >= 0 and self.value <= 1
end
-- -----------------------------------------------------------------------------


-- TrackTranslateEditionUID ----------------------------------------------------
function tracks.TrackTranslateEditionUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackTranslateEditionUID:get_context()
    return {id = 0x66FC, manda = false, parent = tracks.TrackTranslate}
end
-- -----------------------------------------------------------------------------


-- Video -----------------------------------------------------------------------
function tracks.Video:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Video:get_context()
    return {id = 0xE0, manda = false, parent = tracks.TrackEntry}
end

function tracks.Video:get_semantic()
    return {tracks.FlagInterlaced, tracks.FieldOrder, tracks.StereoMode,
        tracks.AlphaMode, tracks.OldStereoMode, tracks.PixelWidth,
        tracks.PixelHeight, tracks.PixelCropBottom, tracks.PixelCropTop,
        tracks.PixelCropLeft, tracks.PixelCropRight, tracks.DisplayWidth,
        tracks.DisplayHeight, tracks.DisplayUnit, tracks.AspectRatioType,
        tracks.UncompressedFourCC, tracks.GammaValue, tracks.FrameRate,
        tracks.Colour, tracks.Projection}
end
-- -----------------------------------------------------------------------------


-- FlagInterlaced --------------------------------------------------------------
function tracks.FlagInterlaced:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FlagInterlaced:get_context()
    return {id = 0x9A, manda = true, parent = tracks.Video}
end

function tracks.FlagInterlaced:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- FieldOrder ------------------------------------------------------------------
function tracks.FieldOrder:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FieldOrder:get_context()
    return {id = 0x9D, manda = true, parent = tracks.Video}
end

function tracks.FieldOrder:validate_data()
    local valid = {0, 1, 2, 6, 9, 14}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- StereoMode ------------------------------------------------------------------
function tracks.StereoMode:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.StereoMode:get_context()
    return {id = 0x53B8, manda = true, parent = tracks.Video}
end

function tracks.StereoMode:validate_data()
    return self.value >= 0 and self.value <= 14
end
-- -----------------------------------------------------------------------------


-- AlphaMode -------------------------------------------------------------------
function tracks.AlphaMode:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.AlphaMode:get_context()
    return {id = 0x53C0, manda = true, parent = tracks.Video}
end

function tracks.AlphaMode:validate_data()
    return self.value >= 0 and self.value <= 1
end
-- -----------------------------------------------------------------------------


-- OldStereoMode ---------------------------------------------------------------
function tracks.OldStereoMode:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.OldStereoMode:get_context()
    return {id = 0x53B9, manda = false, parent = tracks.Video}
end

function tracks.OldStereoMode:validate_data()
    return self.value >= 0 and self.value <= 3
end
-- -----------------------------------------------------------------------------


-- PixelWidth ------------------------------------------------------------------
function tracks.PixelWidth:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PixelWidth:get_context()
    return {id = 0xB0, manda = true, parent = tracks.Video}
end

function tracks.PixelWidth:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- PixelHeight -----------------------------------------------------------------
function tracks.PixelHeight:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PixelHeight:get_context()
    return {id = 0xBA, manda = true, parent = tracks.Video}
end

function tracks.PixelHeight:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- PixelCropBottom -------------------------------------------------------------
function tracks.PixelCropBottom:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PixelCropBottom:get_context()
    return {id = 0x54AA, manda = true, parent = tracks.Video}
end
-- -----------------------------------------------------------------------------


-- PixelCropTop ----------------------------------------------------------------
function tracks.PixelCropTop:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PixelCropTop:get_context()
    return {id = 0x54BB, manda = true, parent = tracks.Video}
end
-- -----------------------------------------------------------------------------


-- PixelCropLeft ---------------------------------------------------------------
function tracks.PixelCropLeft:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PixelCropLeft:get_context()
    return {id = 0x54CC, manda = true, parent = tracks.Video}
end
-- -----------------------------------------------------------------------------


-- PixelCropRight --------------------------------------------------------------
function tracks.PixelCropRight:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PixelCropRight:get_context()
    return {id = 0x54DD, manda = true, parent = tracks.Video}
end
-- -----------------------------------------------------------------------------


-- DisplayWidth ----------------------------------------------------------------
function tracks.DisplayWidth:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.DisplayWidth:get_context()
    return {id = 0x54B0, manda = false, parent = tracks.Video}
end

function tracks.DisplayWidth:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- DisplayHeight ---------------------------------------------------------------
function tracks.DisplayHeight:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.DisplayHeight:get_context()
    return {id = 0x54BA, manda = false, parent = tracks.Video}
end

function tracks.DisplayHeight:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- DisplayUnit -----------------------------------------------------------------
function tracks.DisplayUnit:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.DisplayUnit:get_context()
    return {id = 0x54B2, manda = true, parent = tracks.Video}
end

function tracks.DisplayUnit:validate_data()
    return self.value >= 0 and self.value <= 4
end
-- -----------------------------------------------------------------------------


-- AspectRatioType -------------------------------------------------------------
function tracks.AspectRatioType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.AspectRatioType:get_context()
    return {id = 0x54B3, manda = false, parent = tracks.Video}
end

function tracks.AspectRatioType:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- UncompressedFourCC ----------------------------------------------------------
function tracks.UncompressedFourCC:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.UncompressedFourCC:get_context()
    return {id = 0x2EB524, manda = false, parent = tracks.Video}
end

function tracks.UncompressedFourCC:validate_data_size()
    return self.data_size == 4
end
-- -----------------------------------------------------------------------------


-- GammaValue ------------------------------------------------------------------
function tracks.GammaValue:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.GammaValue:get_context()
    return {id = 0x2FB523, manda = false, parent = tracks.Video}
end

function tracks.GammaValue:validate_data()
    return self.value > 0.0
end
-- -----------------------------------------------------------------------------


-- FrameRate -------------------------------------------------------------------
function tracks.FrameRate:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.FrameRate:get_context()
    return {id = 0x2383E3, manda = false, parent = tracks.Video}
end

function tracks.FrameRate:validate_data()
    return self.value > 0.0
end
-- -----------------------------------------------------------------------------


-- Colour ----------------------------------------------------------------------
function tracks.Colour:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Colour:get_context()
    return {id = 0x55B0, manda = false, parent = tracks.Video}
end

function tracks.Colour:get_semantic()
    return {tracks.MatrixCoefficients, tracks.BitsPerChannel,
        tracks.ChromaSubsamplingHorz, tracks.ChromaSubsamplingVert,
        tracks.CbSubsamplingHorz, tracks.CbSubsamplingVert,
        tracks.ChromaSitingHorz, tracks.ChromaSitingVert, tracks.Range,
        tracks.TransferCharacteristics, tracks.Primaries, tracks.MaxCLL,
        tracks.MaxFALL, tracks.MasteringMetadata}
end
-- -----------------------------------------------------------------------------


-- MatrixCoefficients ----------------------------------------------------------
function tracks.MatrixCoefficients:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MatrixCoefficients:get_context()
    return {id = 0x55B1, manda = true, parent = tracks.Colour}
end

function tracks.MatrixCoefficients:validate_data()
    return self.value >= 0 and self.value <= 14
end
-- -----------------------------------------------------------------------------


-- BitsPerChannel --------------------------------------------------------------
function tracks.BitsPerChannel:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BitsPerChannel:get_context()
    return {id = 0x55B2, manda = true, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- ChromaSubsamplingHorz -------------------------------------------------------
function tracks.ChromaSubsamplingHorz:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ChromaSubsamplingHorz:get_context()
    return {id = 0x55B3, manda = false, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- ChromaSubsamplingVert -------------------------------------------------------
function tracks.ChromaSubsamplingVert:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ChromaSubsamplingVert:get_context()
    return {id = 0x55B4, manda = false, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- CbSubsamplingHorz -----------------------------------------------------------
function tracks.CbSubsamplingHorz:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CbSubsamplingHorz:get_context()
    return {id = 0x55B5, manda = false, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- CbSubsamplingVert -----------------------------------------------------------
function tracks.CbSubsamplingVert:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.CbSubsamplingVert:get_context()
    return {id = 0x55B6, manda = false, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- ChromaSitingHorz ------------------------------------------------------------
function tracks.ChromaSitingHorz:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ChromaSitingHorz:get_context()
    return {id = 0x55B7, manda = true, parent = tracks.Colour}
end

function tracks.ChromaSitingHorz:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- ChromaSitingVert ------------------------------------------------------------
function tracks.ChromaSitingVert:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ChromaSitingVert:get_context()
    return {id = 0x55B8, manda = true, parent = tracks.Colour}
end

function tracks.ChromaSitingVert:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- Range -----------------------------------------------------------------------
function tracks.Range:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Range:get_context()
    return {id = 0x55B9, manda = true, parent = tracks.Colour}
end

function tracks.Range:validate_data()
    return self.value >= 0 and self.value <= 3
end
-- -----------------------------------------------------------------------------


-- TransferCharacteristics -----------------------------------------------------
function tracks.TransferCharacteristics:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TransferCharacteristics:get_context()
    return {id = 0x55BA, manda = true, parent = tracks.Colour}
end

function tracks.TransferCharacteristics:validate_data()
    return self.value >= 0 and self.value <= 18
end
-- -----------------------------------------------------------------------------


-- Primaries -------------------------------------------------------------------
function tracks.Primaries:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Primaries:get_context()
    return {id = 0x55BB, manda = true, parent = tracks.Colour}
end

function tracks.Primaries:validate_data()
    local valid = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 22}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- MaxCLL ----------------------------------------------------------------------
function tracks.MaxCLL:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MaxCLL:get_context()
    return {id = 0x55BC, manda = false, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- MaxFALL ---------------------------------------------------------------------
function tracks.MaxFALL:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MaxFALL:get_context()
    return {id = 0x55BD, manda = false, parent = tracks.Colour}
end
-- -----------------------------------------------------------------------------


-- MasteringMetadata -----------------------------------------------------------
function tracks.MasteringMetadata:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.MasteringMetadata:get_context()
    return {id = 0x55D0, manda = false, parent = tracks.Colour}
end

function tracks.MasteringMetadata:get_semantic()
    return {tracks.PrimaryRChromaticityX, tracks.PrimaryRChromaticityY,
        tracks.PrimaryGChromaticityX, tracks.PrimaryGChromaticityY,
        tracks.PrimaryBChromaticityX, tracks.PrimaryBChromaticityY,
        tracks.WhitePointChromaticityX, tracks.WhitePointChromaticityY,
        tracks.LuminanceMax, tracks.LuminanceMin}
end
-- -----------------------------------------------------------------------------


-- PrimaryRChromaticityX -------------------------------------------------------
function tracks.PrimaryRChromaticityX:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PrimaryRChromaticityX:get_context()
    return {id = 0x55D1, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.PrimaryRChromaticityX:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- PrimaryRChromaticityY -------------------------------------------------------
function tracks.PrimaryRChromaticityY:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PrimaryRChromaticityY:get_context()
    return {id = 0x55D2, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.PrimaryRChromaticityY:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- PrimaryGChromaticityX -------------------------------------------------------
function tracks.PrimaryGChromaticityX:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PrimaryGChromaticityX:get_context()
    return {id = 0x55D3, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.PrimaryGChromaticityX:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- PrimaryGChromaticityY -------------------------------------------------------
function tracks.PrimaryGChromaticityY:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PrimaryGChromaticityY:get_context()
    return {id = 0x55D4, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.PrimaryGChromaticityY:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- PrimaryBChromaticityX -------------------------------------------------------
function tracks.PrimaryBChromaticityX:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PrimaryBChromaticityX:get_context()
    return {id = 0x55D5, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.PrimaryBChromaticityX:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- PrimaryBChromaticityY -------------------------------------------------------
function tracks.PrimaryBChromaticityY:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.PrimaryBChromaticityY:get_context()
    return {id = 0x55D6, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.PrimaryBChromaticityY:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- WhitePointChromaticityX -----------------------------------------------------
function tracks.WhitePointChromaticityX:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.WhitePointChromaticityX:get_context()
    return {id = 0x55D7, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.WhitePointChromaticityX:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- WhitePointChromaticityY -----------------------------------------------------
function tracks.WhitePointChromaticityY:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.WhitePointChromaticityY:get_context()
    return {id = 0x55D8, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.WhitePointChromaticityY:validate_data()
    return self.value >= 0.0 and self.value <= 1.0
end
-- -----------------------------------------------------------------------------


-- LuminanceMax ----------------------------------------------------------------
function tracks.LuminanceMax:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.LuminanceMax:get_context()
    return {id = 0x55D9, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.LuminanceMax:validate_data()
    return self.value >= 0.0
end
-- -----------------------------------------------------------------------------


-- LuminanceMin ----------------------------------------------------------------
function tracks.LuminanceMin:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.LuminanceMin:get_context()
    return {id = 0x55DA, manda = false, parent = tracks.MasteringMetadata}
end

function tracks.LuminanceMin:validate_data()
    return self.value >= 0.0
end
-- -----------------------------------------------------------------------------


-- Projection ------------------------------------------------------------------
function tracks.Projection:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Projection:get_context()
    return {id = 0x7670, manda = false, parent = tracks.Video}
end

function tracks.Projection:get_semantic()
    return {tracks.ProjectionType, tracks.ProjectionPrivate,
        tracks.ProjectionPoseYaw, tracks.ProjectionPosePitch,
        tracks.ProjectionPoseRoll}
end
-- -----------------------------------------------------------------------------


-- ProjectionType --------------------------------------------------------------
function tracks.ProjectionType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ProjectionType:get_context()
    return {id = 0x7671, manda = true, parent = tracks.Projection}
end

function tracks.ProjectionType:validate_data()
    return self.value >= 0 and self.value <= 3
end
-- -----------------------------------------------------------------------------


-- ProjectionPrivate -----------------------------------------------------------
function tracks.ProjectionPrivate:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ProjectionPrivate:get_context()
    return {id = 0x7672, manda = false, parent = tracks.Projection}
end
-- -----------------------------------------------------------------------------


-- ProjectionPoseYaw -----------------------------------------------------------
function tracks.ProjectionPoseYaw:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ProjectionPoseYaw:get_context()
    return {id = 0x7673, manda = true, parent = tracks.Projection}
end

function tracks.ProjectionPoseYaw:validate_data()
    return self.value >= -180.0 and self.value <= 180.0
end
-- -----------------------------------------------------------------------------


-- ProjectionPosePitch ---------------------------------------------------------
function tracks.ProjectionPosePitch:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ProjectionPosePitch:get_context()
    return {id = 0x7674, manda = true, parent = tracks.Projection}
end

function tracks.ProjectionPosePitch:validate_data()
    return self.value >= -90.0 and self.value <= 90.0
end
-- -----------------------------------------------------------------------------


-- ProjectionPoseRoll ----------------------------------------------------------
function tracks.ProjectionPoseRoll:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ProjectionPoseRoll:get_context()
    return {id = 0x7675, manda = true, parent = tracks.Projection}
end

function tracks.ProjectionPoseRoll:validate_data()
    return self.value >= -180.0 and self.value <= 180.0
end
-- -----------------------------------------------------------------------------


-- Audio -----------------------------------------------------------------------
function tracks.Audio:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Audio:get_context()
    return {id = 0xE1, manda = false, parent = tracks.TrackEntry}
end

function tracks.Audio:get_semantic()
    return {tracks.SamplingFrequency, tracks.OutputSamplingFrequency,
        tracks.Channels, tracks.ChannelPositions, tracks.BitDepth,
        tracks.Emphasis}
end
-- -----------------------------------------------------------------------------


-- SamplingFrequency -----------------------------------------------------------
function tracks.SamplingFrequency:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.SamplingFrequency:get_context()
    return {id = 0xB5, manda = true, parent = tracks.Audio}
end

function tracks.SamplingFrequency:validate_data()
    return self.value > 0.0
end
-- -----------------------------------------------------------------------------


-- OutputSamplingFrequency -----------------------------------------------------
function tracks.OutputSamplingFrequency:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.OutputSamplingFrequency:get_context()
    return {id = 0x78B5, manda = false, parent = tracks.Audio}
end

function tracks.OutputSamplingFrequency:validate_data()
    return self.value > 0.0
end
-- -----------------------------------------------------------------------------


-- Channels --------------------------------------------------------------------
function tracks.Channels:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Channels:get_context()
    return {id = 0x9F, manda = true, parent = tracks.Audio}
end

function tracks.Channels:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- ChannelPositions ------------------------------------------------------------
function tracks.ChannelPositions:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ChannelPositions:get_context()
    return {id = 0x7D7B, manda = false, parent = tracks.Audio}
end
-- -----------------------------------------------------------------------------


-- BitDepth --------------------------------------------------------------------
function tracks.BitDepth:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.BitDepth:get_context()
    return {id = 0x6264, manda = false, parent = tracks.Audio}
end

function tracks.BitDepth:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- Emphasis --------------------------------------------------------------------
function tracks.Emphasis:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.Emphasis:get_context()
    return {id = 0x52F1, manda = true, parent = tracks.Audio}
end

function tracks.Emphasis:validate_data()
    local valid = {0, 1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15, 16}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- TrackOperation --------------------------------------------------------------
function tracks.TrackOperation:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackOperation:get_context()
    return {id = 0xE2, manda = false, parent = tracks.TrackEntry}
end

function tracks.TrackOperation:get_semantic()
    return {tracks.TrackCombinePlanes, tracks.TrackJoinBlocks}
end
-- -----------------------------------------------------------------------------


-- TrackCombinePlanes ----------------------------------------------------------
function tracks.TrackCombinePlanes:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackCombinePlanes:get_context()
    return {id = 0xE3, manda = false, parent = tracks.TrackOperation}
end

function tracks.TrackCombinePlanes:get_semantic()
    return {tracks.TrackPlane}
end
-- -----------------------------------------------------------------------------


-- TrackPlane ------------------------------------------------------------------
function tracks.TrackPlane:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackPlane:get_context()
    return {id = 0xE4, manda = true, parent = tracks.TrackCombinePlanes}
end

function tracks.TrackPlane:get_semantic()
    return {tracks.TrackPlaneUID, tracks.TrackPlaneType}
end
-- -----------------------------------------------------------------------------


-- TrackPlaneUID ---------------------------------------------------------------
function tracks.TrackPlaneUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackPlaneUID:get_context()
    return {id = 0xE5, manda = true, parent = tracks.TrackPlane}
end

function tracks.TrackPlaneUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- TrackPlaneType --------------------------------------------------------------
function tracks.TrackPlaneType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackPlaneType:get_context()
    return {id = 0xE6, manda = true, parent = tracks.TrackPlane}
end

function tracks.TrackPlaneType:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- TrackJoinBlocks -------------------------------------------------------------
function tracks.TrackJoinBlocks:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackJoinBlocks:get_context()
    return {id = 0xE9, manda = false, parent = tracks.TrackOperation}
end

function tracks.TrackJoinBlocks:get_semantic()
    return {tracks.TrackJoinUID}
end
-- -----------------------------------------------------------------------------


-- TrackJoinUID ----------------------------------------------------------------
function tracks.TrackJoinUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrackJoinUID:get_context()
    return {id = 0xED, manda = true, parent = tracks.TrackJoinBlocks}
end

function tracks.TrackJoinUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- TrickTrackUID ---------------------------------------------------------------
function tracks.TrickTrackUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrickTrackUID:get_context()
    return {id = 0xC0, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- TrickTrackSegmentUID --------------------------------------------------------
function tracks.TrickTrackSegmentUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrickTrackSegmentUID:get_context()
    return {id = 0xC1, manda = false, parent = tracks.TrackEntry}
end

function tracks.TrickTrackSegmentUID:validate_data_size()
    return self.data_size == 16
end
-- -----------------------------------------------------------------------------


-- TrickTrackFlag --------------------------------------------------------------
function tracks.TrickTrackFlag:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrickTrackFlag:get_context()
    return {id = 0xC6, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- TrickMasterTrackUID ---------------------------------------------------------
function tracks.TrickMasterTrackUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrickMasterTrackUID:get_context()
    return {id = 0xC7, manda = false, parent = tracks.TrackEntry}
end
-- -----------------------------------------------------------------------------


-- TrickMasterTrackSegmentUID --------------------------------------------------
function tracks.TrickMasterTrackSegmentUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.TrickMasterTrackSegmentUID:get_context()
    return {id = 0xC4, manda = false, parent = tracks.TrackEntry}
end

function tracks.TrickMasterTrackSegmentUID:validate_data_size()
    return self.data_size == 16
end
-- -----------------------------------------------------------------------------


-- ContentEncodings ------------------------------------------------------------
function tracks.ContentEncodings:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncodings:get_context()
    return {id = 0x6D80, manda = false, parent = tracks.TrackEntry}
end

function tracks.ContentEncodings:get_semantic()
    return {tracks.ContentEncoding}
end
-- -----------------------------------------------------------------------------


-- ContentEncoding -------------------------------------------------------------
function tracks.ContentEncoding:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncoding:get_context()
    return {id = 0x6240, manda = true, parent = tracks.ContentEncodings}
end

function tracks.ContentEncoding:get_semantic()
    return {tracks.ContentEncodingOrder, tracks.ContentEncodingScope,
        tracks.ContentEncodingType, tracks.ContentCompression,
        tracks.ContentEncryption}
end
-- -----------------------------------------------------------------------------


-- ContentEncodingOrder --------------------------------------------------------
function tracks.ContentEncodingOrder:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncodingOrder:get_context()
    return {id = 0x5031, manda = true, parent = tracks.ContentEncoding}
end
-- -----------------------------------------------------------------------------


-- ContentEncodingScope --------------------------------------------------------
function tracks.ContentEncodingScope:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncodingScope:get_context()
    return {id = 0x5032, manda = true, parent = tracks.ContentEncoding}
end

function tracks.ContentEncodingScope:validate_data()
    local valid = {1, 2, 4}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- ContentEncodingType ---------------------------------------------------------
function tracks.ContentEncodingType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncodingType:get_context()
    return {id = 0x5033, manda = true, parent = tracks.ContentEncoding}
end

function tracks.ContentEncodingType:validate_data()
    return self.value >= 0 and self.value <= 1
end
-- -----------------------------------------------------------------------------


-- ContentCompression ----------------------------------------------------------
function tracks.ContentCompression:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentCompression:get_context()
    return {id = 0x5034, manda = false, parent = tracks.ContentEncoding}
end

function tracks.ContentCompression:get_semantic()
    return {tracks.ContentCompAlgo, tracks.ContentCompSettings}
end
-- -----------------------------------------------------------------------------


-- ContentCompAlgo -------------------------------------------------------------
function tracks.ContentCompAlgo:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentCompAlgo:get_context()
    return {id = 0x4254, manda = true, parent = tracks.ContentCompression}
end

function tracks.ContentCompAlgo:validate_data()
    return self.value >= 0 and self.value <= 3
end
-- -----------------------------------------------------------------------------


-- ContentCompSettings ---------------------------------------------------------
function tracks.ContentCompSettings:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentCompSettings:get_context()
    return {id = 0x4255, manda = false, parent = tracks.ContentCompression}
end
-- -----------------------------------------------------------------------------


-- ContentEncryption -----------------------------------------------------------
function tracks.ContentEncryption:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncryption:get_context()
    return {id = 0x5035, manda = false, parent = tracks.ContentEncoding}
end

function tracks.ContentEncryption:get_semantic()
    return {tracks.ContentEncAlgo, tracks.ContentEncKeyID,
        tracks.ContentEncAESSettings, tracks.ContentSignature,
        tracks.ContentSigKeyID, tracks.ContentSigAlgo,
        tracks.ContentSigHashAlgo}
end
-- -----------------------------------------------------------------------------


-- ContentEncAlgo --------------------------------------------------------------
function tracks.ContentEncAlgo:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncAlgo:get_context()
    return {id = 0x47E1, manda = true, parent = tracks.ContentEncryption}
end

function tracks.ContentEncAlgo:validate_data()
    return self.value >= 0 and self.value <= 5
end
-- -----------------------------------------------------------------------------


-- ContentEncKeyID -------------------------------------------------------------
function tracks.ContentEncKeyID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncKeyID:get_context()
    return {id = 0x47E2, manda = false, parent = tracks.ContentEncryption}
end
-- -----------------------------------------------------------------------------


-- ContentEncAESSettings -------------------------------------------------------
function tracks.ContentEncAESSettings:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentEncAESSettings:get_context()
    return {id = 0x47E7, manda = false, parent = tracks.ContentEncryption}
end

function tracks.ContentEncAESSettings:get_semantic()
    return {tracks.AESSettingsCipherMode}
end
-- -----------------------------------------------------------------------------


-- AESSettingsCipherMode -------------------------------------------------------
function tracks.AESSettingsCipherMode:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.AESSettingsCipherMode:get_context()
    return {id = 0x47E8, manda = true, parent = tracks.ContentEncAESSettings}
end

function tracks.AESSettingsCipherMode:validate_data()
    return self.value >= 1 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- ContentSignature ------------------------------------------------------------
function tracks.ContentSignature:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentSignature:get_context()
    return {id = 0x47E3, manda = false, parent = tracks.ContentEncryption}
end
-- -----------------------------------------------------------------------------


-- ContentSigKeyID -------------------------------------------------------------
function tracks.ContentSigKeyID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentSigKeyID:get_context()
    return {id = 0x47E4, manda = false, parent = tracks.ContentEncryption}
end
-- -----------------------------------------------------------------------------


-- ContentSigAlgo --------------------------------------------------------------
function tracks.ContentSigAlgo:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentSigAlgo:get_context()
    return {id = 0x47E5, manda = false, parent = tracks.ContentEncryption}
end

function tracks.ContentSigAlgo:validate_data()
    return self.value >= 0 and self.value <= 1
end
-- -----------------------------------------------------------------------------


-- ContentSigHashAlgo ----------------------------------------------------------
function tracks.ContentSigHashAlgo:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tracks.ContentSigHashAlgo:get_context()
    return {id = 0x47E6, manda = false, parent = tracks.ContentEncryption}
end

function tracks.ContentSigHashAlgo:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- Cues ------------------------------------------------------------------------
function cues.Cues:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.Cues:get_context()
    return {id = 0x1C53BB6B, manda = false, parent = Segment}
end

function cues.Cues:get_semantic()
    return {cues.CuePoint}
end
-- -----------------------------------------------------------------------------


-- CuePoint --------------------------------------------------------------------
function cues.CuePoint:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CuePoint:get_context()
    return {id = 0xBB, manda = true, parent = cues.Cues}
end

function cues.CuePoint:get_semantic()
    return {cues.CueTime, cues.CueTrackPositions}
end
-- -----------------------------------------------------------------------------


-- CueTime ---------------------------------------------------------------------
function cues.CueTime:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueTime:get_context()
    return {id = 0xB3, manda = true, parent = cues.CuePoint}
end
-- -----------------------------------------------------------------------------


-- CueTrackPositions -----------------------------------------------------------
function cues.CueTrackPositions:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueTrackPositions:get_context()
    return {id = 0xB7, manda = true, parent = cues.CuePoint}
end

function cues.CueTrackPositions:get_semantic()
    return {cues.CueTrack, cues.CueClusterPosition, cues.CueRelativePosition,
        cues.CueDuration, cues.CueBlockNumber, cues.CueCodecState,
        cues.CueReference}
end
-- -----------------------------------------------------------------------------


-- CueTrack --------------------------------------------------------------------
function cues.CueTrack:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueTrack:get_context()
    return {id = 0xF7, manda = true, parent = cues.CueTrackPositions}
end

function cues.CueTrack:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- CueClusterPosition ----------------------------------------------------------
function cues.CueClusterPosition:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueClusterPosition:get_context()
    return {id = 0xF1, manda = true, parent = cues.CueTrackPositions}
end
-- -----------------------------------------------------------------------------


-- CueRelativePosition ---------------------------------------------------------
function cues.CueRelativePosition:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueRelativePosition:get_context()
    return {id = 0xF0, manda = false, parent = cues.CueTrackPositions}
end
-- -----------------------------------------------------------------------------


-- CueDuration -----------------------------------------------------------------
function cues.CueDuration:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueDuration:get_context()
    return {id = 0xB2, manda = false, parent = cues.CueTrackPositions}
end
-- -----------------------------------------------------------------------------


-- CueBlockNumber --------------------------------------------------------------
function cues.CueBlockNumber:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueBlockNumber:get_context()
    return {id = 0x5378, manda = false, parent = cues.CueTrackPositions}
end

function cues.CueBlockNumber:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- CueCodecState ---------------------------------------------------------------
function cues.CueCodecState:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueCodecState:get_context()
    return {id = 0xEA, manda = true, parent = cues.CueTrackPositions}
end
-- -----------------------------------------------------------------------------


-- CueReference ----------------------------------------------------------------
function cues.CueReference:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueReference:get_context()
    return {id = 0xDB, manda = false, parent = cues.CueTrackPositions}
end

function cues.CueReference:get_semantic()
    return {cues.CueRefTime, cues.CueRefCluster, cues.CueRefNumber,
        cues.CueRefCodecState}
end
-- -----------------------------------------------------------------------------


-- CueRefTime ------------------------------------------------------------------
function cues.CueRefTime:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueRefTime:get_context()
    return {id = 0x96, manda = true, parent = cues.CueReference}
end
-- -----------------------------------------------------------------------------


-- CueRefCluster ---------------------------------------------------------------
function cues.CueRefCluster:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueRefCluster:get_context()
    return {id = 0x97, manda = true, parent = cues.CueReference}
end
-- -----------------------------------------------------------------------------


-- CueRefNumber ----------------------------------------------------------------
function cues.CueRefNumber:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueRefNumber:get_context()
    return {id = 0x535F, manda = false, parent = cues.CueReference}
end

function cues.CueRefNumber:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- CueRefCodecState ------------------------------------------------------------
function cues.CueRefCodecState:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function cues.CueRefCodecState:get_context()
    return {id = 0xEB, manda = false, parent = cues.CueReference}
end
-- -----------------------------------------------------------------------------


-- Attachments -----------------------------------------------------------------
function attachments.Attachments:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.Attachments:get_context()
    return {id = 0x1941A469, manda = false, parent = Segment}
end

function attachments.Attachments:get_semantic()
    return {attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- AttachedFile ----------------------------------------------------------------
function attachments.AttachedFile:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.AttachedFile:get_context()
    return {id = 0x61A7, manda = true, parent = attachments.Attachments}
end

function attachments.AttachedFile:get_semantic()
    return {attachments.FileDescription, attachments.FileName,
        attachments.FileMediaType, attachments.FileData, attachments.FileUID,
        attachments.FileReferral, attachments.FileUsedStartTime,
        attachments.FileUsedEndTime}
end
-- -----------------------------------------------------------------------------


-- FileDescription -------------------------------------------------------------
function attachments.FileDescription:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileDescription:get_context()
    return {id = 0x467E, manda = false, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- FileName --------------------------------------------------------------------
function attachments.FileName:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileName:get_context()
    return {id = 0x466E, manda = true, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- FileMediaType ---------------------------------------------------------------
function attachments.FileMediaType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileMediaType:get_context()
    return {id = 0x4660, manda = true, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- FileData --------------------------------------------------------------------
function attachments.FileData:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileData:get_context()
    return {id = 0x465C, manda = true, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- FileUID ---------------------------------------------------------------------
function attachments.FileUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileUID:get_context()
    return {id = 0x46AE, manda = true, parent = attachments.AttachedFile}
end

function attachments.FileUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- FileReferral ----------------------------------------------------------------
function attachments.FileReferral:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileReferral:get_context()
    return {id = 0x4675, manda = false, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- FileUsedStartTime -----------------------------------------------------------
function attachments.FileUsedStartTime:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileUsedStartTime:get_context()
    return {id = 0x4661, manda = false, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- FileUsedEndTime -------------------------------------------------------------
function attachments.FileUsedEndTime:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function attachments.FileUsedEndTime:get_context()
    return {id = 0x4662, manda = false, parent = attachments.AttachedFile}
end
-- -----------------------------------------------------------------------------


-- Chapters --------------------------------------------------------------------
function chapters.Chapters:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.Chapters:get_context()
    return {id = 0x1043A770, manda = false, parent = Segment}
end

function chapters.Chapters:get_semantic()
    return {chapters.EditionEntry}
end

-- Get Default Edition --
function chapters.Chapters:get_default_edition()
    -- Matroska specs defines a default edtion as follows
    -- first edition with Default-Flag set to 1
    -- otherwise first edition is the default one

    if #self.value == 0 then return nil end
    
    local edition, idx = self:find_child(chapters.EditionEntry)
    while edition do
        if edition:get_child(chapters.EditionFlagDefault).value then
            return edition
        end
        -- next edition
        edition = self:find_next_child(idx)
    end

    -- no default edition found, return first edition
    return self:find_child(chapters.EditionEntry)
end
-- -----------------------------------------------------------------------------


-- EditionEntry ----------------------------------------------------------------
function chapters.EditionEntry:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionEntry:get_context()
    return {id = 0x45B9, manda = true, parent = chapters.Chapters}
end

function chapters.EditionEntry:get_semantic()
    return {chapters.EditionUID, chapters.EditionFlagHidden,
        chapters.EditionFlagDefault, chapters.EditionFlagOrdered,
        chapters.EditionDisplay, chapters.ChapterAtom}
end
-- -----------------------------------------------------------------------------


-- EditionUID ------------------------------------------------------------------
function chapters.EditionUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionUID:get_context()
    return {id = 0x45BC, manda = false, parent = chapters.EditionEntry}
end

function chapters.EditionUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- EditionFlagHidden -----------------------------------------------------------
function chapters.EditionFlagHidden:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionFlagHidden:get_context()
    return {id = 0x45BD, manda = true, parent = chapters.EditionEntry}
end

function chapters.EditionFlagHidden:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- EditionFlagDefault ----------------------------------------------------------
function chapters.EditionFlagDefault:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionFlagDefault:get_context()
    return {id = 0x45DB, manda = true, parent = chapters.EditionEntry}
end

function chapters.EditionFlagDefault:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- EditionFlagOrdered ----------------------------------------------------------
function chapters.EditionFlagOrdered:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionFlagOrdered:get_context()
    return {id = 0x45DD, manda = true, parent = chapters.EditionEntry}
end

function chapters.EditionFlagOrdered:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- EditionDisplay --------------------------------------------------------------
function chapters.EditionDisplay:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionDisplay:get_context()
    return {id = 0x4520, manda = false, parent = chapters.EditionEntry}
end

function chapters.EditionDisplay:get_semantic()
    return {chapters.EditionString, chapters.EditionLanguageIETF}
end
-- -----------------------------------------------------------------------------


-- EditionString ---------------------------------------------------------------
function chapters.EditionString:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionString:get_context()
    return {id = 0x4521, manda = true, parent = chapters.EditionDisplay}
end
-- -----------------------------------------------------------------------------


-- EditionLanguageIETF ---------------------------------------------------------
function chapters.EditionLanguageIETF:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.EditionLanguageIETF:get_context()
    return {id = 0x45E4, manda = false, parent = chapters.EditionDisplay}
end
-- -----------------------------------------------------------------------------


-- ChapterAtom -----------------------------------------------------------------
function chapters.ChapterAtom:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterAtom:get_context()
    return {id = 0xB6, manda = true, parent = chapters.EditionEntry}
end

function chapters.ChapterAtom:get_semantic()
    return {chapters.ChapterUID, chapters.ChapterStringUID,
        chapters.ChapterTimeStart, chapters.ChapterTimeEnd,
        chapters.ChapterFlagHidden, chapters.ChapterFlagEnabled,
        chapters.ChapterSegmentUUID, chapters.ChapterSkipType,
        chapters.ChapterSegmentEditionUID, chapters.ChapterPhysicalEquiv,
        chapters.ChapterTrack, chapters.ChapterDisplay, chapters.ChapProcess,
        chapters.ChapterAtom}
end
-- -----------------------------------------------------------------------------


-- ChapterUID ------------------------------------------------------------------
function chapters.ChapterUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterUID:get_context()
    return {id = 0x73C4, manda = true, parent = chapters.ChapterAtom}
end

function chapters.ChapterUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- ChapterStringUID ------------------------------------------------------------
function chapters.ChapterStringUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterStringUID:get_context()
    return {id = 0x5654, manda = false, parent = chapters.ChapterAtom}
end
-- -----------------------------------------------------------------------------


-- ChapterTimeStart ------------------------------------------------------------
function chapters.ChapterTimeStart:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterTimeStart:get_context()
    return {id = 0x91, manda = true, parent = chapters.ChapterAtom}
end
-- -----------------------------------------------------------------------------


-- ChapterTimeEnd --------------------------------------------------------------
function chapters.ChapterTimeEnd:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterTimeEnd:get_context()
    return {id = 0x92, manda = false, parent = chapters.ChapterAtom}
end
-- -----------------------------------------------------------------------------


-- ChapterFlagHidden -----------------------------------------------------------
function chapters.ChapterFlagHidden:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterFlagHidden:get_context()
    return {id = 0x98, manda = true, parent = chapters.ChapterAtom}
end

function chapters.ChapterFlagHidden:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- ChapterFlagEnabled ----------------------------------------------------------
function chapters.ChapterFlagEnabled:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterFlagEnabled:get_context()
    return {id = 0x4598, manda = true, parent = chapters.ChapterAtom}
end

function chapters.ChapterFlagEnabled:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- ChapterSegmentUUID ----------------------------------------------------------
function chapters.ChapterSegmentUUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterSegmentUUID:get_context()
    return {id = 0x6E67, manda = false, parent = chapters.ChapterAtom}
end

function chapters.ChapterSegmentUUID:validate_data_size()
    return self.data_size == 16
end

function chapters.ChapterSegmentUUID:validate_data()
    for v in self.value do
        if string.byte(v, 1) > 0 then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- ChapterSkipType -------------------------------------------------------------
function chapters.ChapterSkipType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterSkipType:get_context()
    return {id = 0x4588, manda = false, parent = chapters.ChapterAtom}
end

function chapters.ChapterSkipType:validate_data()
    return self.value >= 0 and self.value <= 6
end
-- -----------------------------------------------------------------------------


-- ChapterSegmentEditionUID ----------------------------------------------------
function chapters.ChapterSegmentEditionUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterSegmentEditionUID:get_context()
    return {id = 0x6EBC, manda = false, parent = chapters.ChapterAtom}
end

function chapters.ChapterSegmentEditionUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- ChapterPhysicalEquiv --------------------------------------------------------
function chapters.ChapterPhysicalEquiv:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterPhysicalEquiv:get_context()
    return {id = 0x63C3, manda = false, parent = chapters.ChapterAtom}
end
-- -----------------------------------------------------------------------------


-- ChapterTrack ----------------------------------------------------------------
function chapters.ChapterTrack:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterTrack:get_context()
    return {id = 0x8F, manda = false, parent = chapters.ChapterAtom}
end

function chapters.ChapterTrack:get_semantic()
    return {chapters.ChapterTrackUID}
end
-- -----------------------------------------------------------------------------


-- ChapterTrackUID -------------------------------------------------------------
function chapters.ChapterTrackUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterTrackUID:get_context()
    return {id = 0x89, manda = true, parent = chapters.ChapterTrack}
end

function chapters.ChapterTrackUID:validate_data()
    return self.value > 0
end
-- -----------------------------------------------------------------------------


-- ChapterDisplay --------------------------------------------------------------
function chapters.ChapterDisplay:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapterDisplay:get_context()
    return {id = 0x80, manda = false, parent = chapters.ChapterAtom}
end

function chapters.ChapterDisplay:get_semantic()
    return {chapters.ChapString, chapters.ChapLanguage,
        chapters.ChapLanguageBCP47, chapters.ChapCountry}
end
-- -----------------------------------------------------------------------------


-- ChapString ------------------------------------------------------------------
function chapters.ChapString:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapString:get_context()
    return {id = 0x85, manda = true, parent = chapters.ChapterDisplay}
end
-- -----------------------------------------------------------------------------


-- ChapLanguage ----------------------------------------------------------------
function chapters.ChapLanguage:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapLanguage:get_context()
    return {id = 0x437C, manda = true, parent = chapters.ChapterDisplay}
end
-- -----------------------------------------------------------------------------


-- ChapLanguageBCP47 -----------------------------------------------------------
function chapters.ChapLanguageBCP47:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapLanguageBCP47:get_context()
    return {id = 0x437D, manda = false, parent = chapters.ChapterDisplay}
end
-- -----------------------------------------------------------------------------


-- ChapCountry -----------------------------------------------------------------
function chapters.ChapCountry:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapCountry:get_context()
    return {id = 0x437E, manda = false, parent = chapters.ChapterDisplay}
end
-- -----------------------------------------------------------------------------


-- ChapProcess -----------------------------------------------------------------
function chapters.ChapProcess:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapProcess:get_context()
    return {id = 0x6944, manda = false, parent = chapters.ChapterAtom}
end

function chapters.ChapProcess:get_semantic()
    return {chapters.ChapProcessCodecID, chapters.ChapProcessPrivate,
        chapters.ChapProcessCommand}
end
-- -----------------------------------------------------------------------------


-- ChapProcessCodecID ----------------------------------------------------------
function chapters.ChapProcessCodecID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapProcessCodecID:get_context()
    return {id = 0x6955, manda = true, parent = chapters.ChapProcess}
end
-- -----------------------------------------------------------------------------


-- ChapProcessPrivate ----------------------------------------------------------
function chapters.ChapProcessPrivate:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapProcessPrivate:get_context()
    return {id = 0x450D, manda = false, parent = chapters.ChapProcess}
end
-- -----------------------------------------------------------------------------


-- ChapProcessCommand ----------------------------------------------------------
function chapters.ChapProcessCommand:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapProcessCommand:get_context()
    return {id = 0x6911, manda = false, parent = chapters.ChapProcess}
end

function chapters.ChapProcessCommand:get_semantic()
    return {chapters.ChapProcessTime, chapters.ChapProcessData}
end
-- -----------------------------------------------------------------------------


-- ChapProcessTime -------------------------------------------------------------
function chapters.ChapProcessTime:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapProcessTime:get_context()
    return {id = 0x6922, manda = true, parent = chapters.ChapProcessCommand}
end

function chapters.ChapProcessTime:validate_data()
    return self.value >= 0 and self.value <= 2
end
-- -----------------------------------------------------------------------------


-- ChapProcessData -------------------------------------------------------------
function chapters.ChapProcessData:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function chapters.ChapProcessData:get_context()
    return {id = 0x6933, manda = true, parent = chapters.ChapProcessCommand}
end
-- -----------------------------------------------------------------------------


-- Tags ------------------------------------------------------------------------
function tags.Tags:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.Tags:get_context()
    return {id = 0x1254C367, manda = false, parent = Segment}
end

function tags.Tags:get_semantic()
    return {tags.Tag}
end
-- -----------------------------------------------------------------------------


-- Tag -------------------------------------------------------------------------
function tags.Tag:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.Tag:get_context()
    return {id = 0x7373, manda = true, parent = tags.Tags}
end

function tags.Tag:get_semantic()
    return {tags.Targets, tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- Targets ---------------------------------------------------------------------
function tags.Targets:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.Targets:get_context()
    return {id = 0x63C0, manda = true, parent = tags.Tag}
end

function tags.Targets:get_semantic()
    return {tags.TargetTypeValue, tags.TargetType, tags.TagTrackUID,
        tags.TagEditionUID, tags.TagChapterUID, tags.TagAttachmentUID}
end
-- -----------------------------------------------------------------------------


-- TargetTypeValue -------------------------------------------------------------
function tags.TargetTypeValue:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TargetTypeValue:get_context()
    return {id = 0x68CA, manda = true, parent = tags.Targets}
end

function tags.TargetTypeValue:validate_data()
    local valid = {70, 60, 50, 40, 30, 20, 10}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- TargetType ------------------------------------------------------------------
function tags.TargetType:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TargetType:get_context()
    return {id = 0x63CA, manda = false, parent = tags.Targets}
end

function tags.TargetType:validate_data()
    local valid = {"COLLECTION", "EDITION", "ISSUE", "VOLUME", "OPUS", "SEASON",
        "SEQUEL", "ALBUM", "OPERA", "CONCERT", "MOVIE", "EPISODE", "PART",
        "SESSION", "TRACK", "SONG", "CHAPTER", "SUBTRACK", "MOVEMENT",
        "SCENE", "SHOT"}
    for v in valid do
        if v == self.value then
            return true
        end
    end
    return false
end
-- -----------------------------------------------------------------------------


-- TagTrackUID -----------------------------------------------------------------
function tags.TagTrackUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagTrackUID:get_context()
    return {id = 0x63C5, manda = false, parent = tags.Targets}
end
-- -----------------------------------------------------------------------------


-- TagEditionUID ---------------------------------------------------------------
function tags.TagEditionUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagEditionUID:get_context()
    return {id = 0x63C9, manda = false, parent = tags.Targets}
end
-- -----------------------------------------------------------------------------


-- TagChapterUID ---------------------------------------------------------------
function tags.TagChapterUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagChapterUID:get_context()
    return {id = 0x63C4, manda = false, parent = tags.Targets}
end
-- -----------------------------------------------------------------------------


-- TagAttachmentUID ------------------------------------------------------------
function tags.TagAttachmentUID:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagAttachmentUID:get_context()
    return {id = 0x63C6, manda = false, parent = tags.Targets}
end
-- -----------------------------------------------------------------------------


-- SimpleTag -------------------------------------------------------------------
function tags.SimpleTag:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.SimpleTag:get_context()
    return {id = 0x67C8, manda = true, parent = tags.Tag}
end

function tags.SimpleTag:get_semantic()
    return {tags.TagName, tags.TagLanguage, tags.TagLanguageBCP47,
        tags.TagDefault, tags.TagDefaultBogus, tags.TagString, tags.TagBinary,
        tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- TagName ---------------------------------------------------------------------
function tags.TagName:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagName:get_context()
    return {id = 0x45A3, manda = true, parent = tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- TagLanguage -----------------------------------------------------------------
function tags.TagLanguage:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagLanguage:get_context()
    return {id = 0x447A, manda = true, parent = tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- TagLanguageBCP47 ------------------------------------------------------------
function tags.TagLanguageBCP47:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagLanguageBCP47:get_context()
    return {id = 0x447B, manda = false, parent = tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- TagDefault ------------------------------------------------------------------
function tags.TagDefault:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagDefault:get_context()
    return {id = 0x4484, manda = true, parent = tags.SimpleTag}
end

function tags.TagDefault:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- TagDefaultBogus -------------------------------------------------------------
function tags.TagDefaultBogus:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagDefaultBogus:get_context()
    return {id = 0x44B4, manda = true, parent = tags.SimpleTag}
end

function tags.TagDefaultBogus:validate_data()
    return self.value == 0 or self.value == 1
end
-- -----------------------------------------------------------------------------


-- TagString -------------------------------------------------------------------
function tags.TagString:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagString:get_context()
    return {id = 0x4487, manda = false, parent = tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- TagBinary -------------------------------------------------------------------
function tags.TagBinary:new()
    local elem = {}
    setmetatable(elem, self)
    self.__index = self
    return elem
end

function tags.TagBinary:get_context()
    return {id = 0x4485, manda = false, parent = tags.SimpleTag}
end
-- -----------------------------------------------------------------------------


-- Export module
local module = {
    Semantic = {ebml.EBML, Segment}, -- Matroska semantic
    Segment = Segment,
    seekhead = seekhead,
    info = info,
    tracks = tracks,
    cluster = cluster,
    chapters = chapters,
    cues = cues,
    attachs = attachments,
    tags = tags
}

return module