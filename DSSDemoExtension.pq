// This file contains your Data Connector logic
section DSSDemoExtension;

// Helper Fuction
Value.WaitFor = (producer as function, interval as function, optional count as number) as any =>
    let
        list = List.Generate(
            () => {0, null},
            (state) => state{0} <> null and (count = null or state{0} < count),
            (state) => if state{1} <> null then {null, state{1}} else {1 + state{0}, Function.InvokeAfter(() => producer(state{0}), interval(state{0}))},
            (state) => state{1})
    in
        List.Last(list);

// Request authentication token
Login = (user,pass,currenttime) =>
    let
        endpoint = "https://hosted.datascopeapi.reuters.com/RestApi/v1/Authentication/RequestToken",
        body = "{""Credentials"": {""Username"": """ & user & """,""Password"": """ & pass & """}}",
        response=Web.Contents(endpoint,[
                        Headers=[#"Content-Type"="application/json",
                                MyHeader=currenttime], 
                        Content=Text.ToBinary(body)]), 
        responseBody= Json.Document(response),
        value = responseBody[value]
    in
        "Token"&value;



CheckStatus = (token,location) =>
    let
        jobId = Value.WaitFor(
        (iteration) =>
            let
                url = location,
                response = Web.Contents(url, [Headers=[Authorization=token, #"Content-Type"="application/json"],ManualStatusHandling={202}]),
                status = Value.Metadata(response)[Response.Status],
                jobId=if status = 200 then Json.Document(response)[JobId]
                else null
            in
                jobId,
        (iteration) => #duration(0, 0, 0, Number.Power(2, iteration)),5)
        
    in
        jobId;

GetData = (token,jobId) =>
    let
        endpoint = "https://hosted.datascopeapi.reuters.com/RestApi/v1/Extractions/RawExtractionResults('" & jobId & "')/$value",
        Source = Csv.Document(Web.Contents(
                endpoint, 
                [Headers=
                    [Authorization=token, 
                    #"Content-Type"="application/json"]
                ]),
                [Delimiter=",", Encoding=1252, QuoteStyle=QuoteStyle.None])
    in
        Source;

ExtractRaw = (token) =>
    let
        body = "{ ""ExtractionRequest"": {""@odata.type"": ""#ThomsonReuters.Dss.Api.Extractions.ExtractionRequests.TickHistoryTimeAndSalesExtractionRequest"", ""ContentFieldNames"": [
""Auction - Exchange Time"",
""Auction - Price"",
""Auction - Qualifiers"",
""Auction - Volume"",
""Correction - Accumulated Volume"",
""Correction - Ask Price"",
""Correction - Bid Price"",
""Correction - Buyer ID"",
""Correction - Exchange Time"",
""Correction - Exchange/Contributor ID"",
""Correction - Market VWAP"",
""Correction - Original Date"",
""Correction - Original Exchange Time"",
""Correction - Original Price"",
""Correction - Original Sequence Number"",
""Correction - Original Volume"",
""Correction - PE Ratio"",
""Correction - Price"",
""Correction - Qualifiers"",
""Correction - Seller ID"",
""Correction - Sequence Number"",
""Correction - Volume"",
""Market Conditions - Qualifiers"",
""Quote - Ask Implied Volatility"",
""Quote - Ask Price"",
""Quote - Ask Size"",
""Quote - Ask Yield"",
""Quote - Asset Swap Spread"",
""Quote - Bench Price"",
""Quote - Benchmark Spread"",
""Quote - Bid Implied Volatility"",
""Quote - Bid Price"",
""Quote - Bid Size"",
""Quote - Bid Tick"",
""Quote - Bid Yield"",
""Quote - BPV"",
""Quote - Buyer ID"",
""Quote - Contributor Location Code"",
""Quote - Convexity"",
""Quote - Crack"",
""Quote - Date"",
""Quote - Duration"",
""Quote - Exchange Time"",
""Quote - Exchange/Contributor ID"",
""Quote - Forecast High"",
""Quote - Forecast Low"",
""Quote - Freight Price"",
""Quote - High"",
""Quote - Implied Volatility"",
""Quote - ISMA Ask Yield"",
""Quote - ISMA Bid Yield"",
""Quote - Low"",
""Quote - Lower Limit Price"",
""Quote - Mid Price"",
""Quote - Modified Duration"",
""Quote - Number of Buyers"",
""Quote - Number of Sellers"",
""Quote - Open"",
""Quote - Parity"",
""Quote - Premium"",
""Quote - Price"",
""Quote - Qualifiers"",
""Quote - Seller ID"",
""Quote - Sequence Number"",
""Quote - Swap Point"",
""Quote - Swap Spread"",
""Quote - Theoretical Price"",
""Quote - Top"",
""Quote - Upper Limit Price"",
""Quote - Volume"",
""Quote - Yield"",
""Settlement Price - Date"",
""Settlement Price - Price"",
""Trade - Accumulated Volume"",
""Trade - Actual"",
""Trade - Ask Price"",
""Trade - Ask Size"",
""Trade - Ask Yield"",
""Trade - Bench Price"",
""Trade - Bid Price"",
""Trade - Bid Size"",
""Trade - Bid Yield"",
""Trade - Block Trade"",
""Trade - Buyer ID"",
""Trade - Contributor Location Code"",
""Trade - Crack"",
""Trade - Date"",
""Trade - Exchange Time"",
""Trade - Exchange/Contributor ID"",
""Trade - Forecast High"",
""Trade - Forecast Low"",
""Trade - Forecast"",
""Trade - Freight Price"",
""Trade - High"",
""Trade - Implied Volatility"",
""Trade - Low"",
""Trade - Lower Limit Price"",
""Trade - Market VWAP"",
""Trade - Mid Price"",
""Trade - Number of Forecasts"",
""Trade - Offer"",
""Trade - Open Interest"",
""Trade - Open"",
""Trade - Original Price"",
""Trade - Original Volume"",
""Trade - PE Ratio"",
""Trade - Premium"",
""Trade - Price"",
""Trade - Prior"",
""Trade - Qualifiers"",
""Trade - Revised"",
""Trade - Seller ID"",
""Trade - Sequence Number"",
""Trade - Tick Direction"",
""Trade - Top"",
""Trade - Turnover"",
""Trade - Upper Limit Price"",
""Trade - Volume"",
""Trade - Yield""
] , ""IdentifierList"": {""@odata.type"": ""#ThomsonReuters.Dss.Api.Extractions.ExtractionRequests.InstrumentIdentifierList"",""InstrumentIdentifiers"": [
{""Identifier"": ""TRI.N"",
""IdentifierType"": ""Ric""}
] },""Condition"":{""MessageTimeStampIn"": ""GmtUtc"", ""ApplyCorrectionsAndCancellations"": false, ""ReportDateRangeType"": ""Range"", ""QueryStartDate"": ""2018-01-01T15:30:00.000Z"", ""QueryEndDate"": ""2018-01-30T15:30:00.000Z"", ""DisplaySourceRIC"": true }}}",

        endpoint = "https://hosted.datascopeapi.reuters.com/RestApi/v1/Extractions/ExtractRaw",
       
        response = Web.Contents(endpoint, [Headers=[#"Authorization"=token, #"Content-Type"="application/json",#"Prefer"= "respond-async;wait=1"], Content=Text.ToBinary(body),ManualStatusHandling={400,202}]),
        status = Value.Metadata(response)[Response.Status],

        jobId=if status = 200 then Json.Document(response)[JobId]
        else if status = 202 then CheckStatus(token,Value.Metadata(response)[Headers][#"Location"])
        else Error.Record("HTTP Status",Text.From(status), Json.Document(response)[error][message])
    in
        jobId;

ExtractTRTH_TimeSeries = (token, ric) =>
    let
        endpoint = "https://hosted.datascopeapi.reuters.com/RestApi/v1/Extractions/ExtractRaw",
        body = 
        "{
            ""ExtractionRequest"": 
            {
                ""@odata.type"": ""#ThomsonReuters.Dss.Api.Extractions.ExtractionRequests.ElektronTimeseriesExtractionRequest"",
                ""ContentFieldNames"": 
                [
                    ""Instrument ID"",
                    ""Bid"",
                    ""Ask"",
                    ""High"",
                    ""Low"",
                    ""Last"",
                    ""Volume"",
                    ""Trade Date""
                ],
                ""IdentifierList"": 
                {
                    ""@odata.type"": ""#ThomsonReuters.Dss.Api.Extractions.ExtractionRequests.InstrumentIdentifierList"",
                    ""InstrumentIdentifiers"":
                    [
                        {
                            ""Identifier"":"""& ric &""",
                            ""IdentifierType"":""Ric""
                        }
                    ]
                },
                ""Condition"":
                {
                    ""ReportDateRangeType"":""Relative"",
                    ""RelativeEndDaysAgo"": 1,
                    ""RelativeStartDaysAgo"": 30
                }
            }
        }",
        response = Web.Contents(
                        endpoint, 
                        [Headers=
                            [#"Authorization"=token, 
                             #"Content-Type"="application/json",
                             #"Prefer"= "respond-async;wait=1"], 
                         Content=Text.ToBinary(body),
                         ManualStatusHandling={400,202}]),
        status = Value.Metadata(response)[Response.Status],

        jobId=if status = 200 then Json.Document(response)[JobId]
        else if status = 202 then CheckStatus(token,Value.Metadata(response)[Headers][#"Location"])
        else Error.Record("HTTP Status",Text.From(status), Json.Document(response)[error][message])
    in
        jobId;

ExtractDSS_Intraday= (token, ric) =>
    let
        endpoint = "https://hosted.datascopeapi.reuters.com/RestApi/v1/Extractions/ExtractRaw",
        body = 
    "{
      ""ExtractionRequest"": 
          {
            ""@odata.type"": ""#ThomsonReuters.Dss.Api.Extractions.ExtractionRequests.IntradayPricingExtractionRequest"",
            ""ContentFieldNames"": [
                ""RIC"",
                ""Ask Price"",
                ""Bid Price"",
                ""Currency Code"",
                ""Exchange Code"",
                ""High Price"",
                ""Low Price"",
                ""Open Price"",
                ""Previous Close Date"",
                ""Previous Close Price"",
                ""Security Description"",
                ""Last Update Time""
            ],
            ""IdentifierList"": {
                ""@odata.type"": ""#ThomsonReuters.Dss.Api.Extractions.ExtractionRequests.InstrumentIdentifierList"",  
                ""InstrumentIdentifiers"": [
                    { ""Identifier"": ""JPY="", ""IdentifierType"": ""Ric"" },
                    { ""Identifier"": ""EUR="", ""IdentifierType"": ""Ric"" },
                    { ""Identifier"": ""INR="", ""IdentifierType"": ""Ric"" }
                ]
            },
            ""Condition"": { ""ScalableCurrency"": true }
            }
        }",
        response = Web.Contents(endpoint, [Headers=[#"Authorization"=token, #"Content-Type"="application/json",#"Prefer"= "respond-async"], Content=Text.ToBinary(body),ManualStatusHandling={400,202},IsRetry=true]),
        status = Value.Metadata(response)[Response.Status],

        jobId=if status = 200 then Json.Document(response)[JobId]
        else if status = 202 then CheckStatus(token,Value.Metadata(response)[Headers][#"Location"])
        else Error.Record("HTTP Status",Text.From(status), Json.Document(response)[error][message])
    in
        jobId;

[DataSource.Kind="DSSDemoExtension", Publish="DSSDemoExtension.Publish1"]
shared DSSDemoExtension.TRTHTimeSeries = (Ricname as text) =>
    let 
    DSSUserName = Extension.CurrentCredential()[Username],
    DSSPassword = Extension.CurrentCredential()[Password],
    currentdate = Date.ToText(DateTime.Date(DateTime.LocalNow())),
    //1)	Request authentication token
    token = Login(DSSUserName,DSSPassword,currentdate),
    //2)	Request historical data from the server, using an on demand request and 3)	Check the request status
    jobId = ExtractTRTH_TimeSeries(token,Ricname),
    //4)	Retrieve the data
    source = if Value.Is(jobId, type text) then
        GetData(token,jobId)
    else 
        jobId
    in
        source;

[DataSource.Kind="DSSDemoExtension", Publish="DSSDemoExtension.Publish2"]
shared DSSDemoExtension.DSSIntraday = (Ricname as text) =>
    let 
    DSSUserName = Extension.CurrentCredential()[Username],
    DSSPassword = Extension.CurrentCredential()[Password],
    currentdate = Date.ToText(DateTime.Date(DateTime.LocalNow())),
    token = Login(DSSUserName,DSSPassword,currentdate),
    jobId = ExtractDSS_Intraday(token,Ricname),
    source = if Value.Is(jobId, type text) then
        GetData(token,jobId)
    else 
        jobId
    in
        source;

[DataSource.Kind="DSSDemoExtension", Publish="DSSDemoExtension.Publish3"]
shared DSSDemoExtension.ExtractRequestFromFile = (Ricname as text) =>
    let 
    DSSUserName = Extension.CurrentCredential()[Username],
    DSSPassword = Extension.CurrentCredential()[Password],
    currentdate = Date.ToText(DateTime.Date(DateTime.LocalNow())),
    token = Login(DSSUserName,DSSPassword,currentdate),
    jobId = ExtractRaw(token),
    source = if Value.Is(jobId, type text) then
        GetData(token,jobId)
    else 
        jobId
    in
        source;

// Data Source Kind description
DSSDemoExtension = [
    Authentication = [
        UsernamePassword = [UsernameLabel="DSS Username",PasswordLabel="DSS Password"]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
DSSDemoExtension.Publish1 = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle1"), Extension.LoadString("ButtonHelp1") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = DSSDemoExtension.Icons,
    SourceTypeImage = DSSDemoExtension.Icons
];

// Data Source UI publishing description
DSSDemoExtension.Publish2 = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle2"), Extension.LoadString("ButtonHelp2") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = DSSDemoExtension.Icons,
    SourceTypeImage = DSSDemoExtension.Icons
];

// Data Source UI publishing description
DSSDemoExtension.Publish3 = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle2"), Extension.LoadString("ButtonHelp2") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = DSSDemoExtension.Icons,
    SourceTypeImage = DSSDemoExtension.Icons
];

DSSDemoExtension.Icons = [
    Icon16 = { Extension.Contents("PQExtension216.png"), Extension.Contents("PQExtension220.png"), Extension.Contents("PQExtension224.png"), Extension.Contents("PQExtension232.png") },
    Icon32 = { Extension.Contents("PQExtension232.png"), Extension.Contents("PQExtension240.png"), Extension.Contents("PQExtension248.png"), Extension.Contents("PQExtension264.png") }
];
