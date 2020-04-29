### Begin Yelp Section ###
# For more details on Yelp's API parameters,
# go to https://www.yelp.com/developers/documentation/v3/business

# Define API query parameters
$yelpAPIKey         = <# replace with your API key #>
$yelpSearchCity     = <# replace with the city you want to search in #>
$yelpSearchState    = <# replace with the state you want to search in #>
$yelpResultLimit    = 200 <# replace with the total number of results you want Yelp to return #>
$yelpRESTUri        = 'https://api.yelp.com/v3/businesses/search' # Do not change
$yelpSearchCityFull = "?location=$yelpSearchCity, $yelpSearchState" # Search city and state
$yelpSearchTerm     = '&term=restaurants' # Search term
$yelpSearchCategory = '&category=restaurants' # Search category
$yelpSearchLimit    = '&limit=50' # Number of results to return (1-50, max 50)
$yelpSearchOffset   = 0 # offset results to return
# $searchSortBy     = '&sort_by=rating' # Can be added to $yelpFullUri to change the sorting of the results
$yelpHeaders        = @{"Authorization"="Bearer {0}" -f $yelpAPIKey} # Passes your key to with the REST queries
$yelpResults        = @{} # Declare hash table to store query results

# Query API
try {
    Write-Host "========== Yelp API =========="
    Write-Host "Connecting to Yelp API..."
    do {
        if ($yelpResults.count -eq 0) {
            Write-Host "Querying for data offset by" $yelpSearchOffset"..."
            $yelpFullUri = $yelpRESTUri + $yelpSearchCityFull + $yelpSearchTerm + $yelpSearchCategory + $yelpSearchLimit + "&offset=" + $yelpSearchOffset
            $yelpResults = (Invoke-RestMethod -Uri $yelpFullUri -Headers $yelpHeaders)
            $yelpSearchOffset = 1  
        }
        else {
            Write-Host "Querying for data offset by" $yelpSearchOffset"..."
            $yelpFullUri = $yelpRESTUri + $yelpSearchCityFull + $yelpSearchTerm + $yelpSearchCategory + $yelpSearchLimit + "&offset=" + $yelpSearchOffset
            $yelpResults.businesses += (Invoke-RestMethod -Uri $yelpFullUri -Headers $yelpHeaders).businesses
        }
        $yelpSearchOffset += 50
    } while ($yelpSearchOffset -lt $yelpResultLimit)
    Write-Host "Yelp API query successful.`nYelp returned data for" $yelpResults.businesses.count "businesses."

    # Filter Yelp data and format for JSON
    try {
        Write-Host "Filtering and formatting Yelp data..."
        # Filter by city
        $yelpResults.businesses = $yelpResults.businesses | Where-Object {$_.location.city -eq $yelpSearchCity}
        # Filter by column
        $yelpResults = $yelpResults.businesses | Select-Object "id","alias","name","location","categories","image_url","is_closed", "url","review_count","rating","price","display_phone"
        $yelpResultsId = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty id
        }
        $yelpResultsAlias = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty alias
        }
        $yelpResultsName = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty name
        }
        $yelpResultsAddress = foreach ($yelpResult in $yelpResults) {
            # Flattening address fields into single string
            $yelpFullAddress = $null
            $yelpAddress1 = $yelpResult.location | Select-Object -ExpandProperty address1
            $yelpAddress2 = $yelpResult.location | Select-Object -ExpandProperty address2
            $yelpAddress3 = $yelpResult.location | Select-Object -ExpandProperty address3
            $yelpCity = $yelpResult.location | Select-Object -ExpandProperty city
            $yelpState = $yelpResult.location | Select-Object -ExpandProperty state
            $yelpZip = $yelpResult.location | Select-Object -ExpandProperty zip_code
            if ($yelpAddress1 -ne "") { $yelpFullAddress = ($yelpAddress1) }
            if ($yelpAddress2 -ne "") { $yelpFullAddress += (" " + $yelpAddress2) }
            if ($yelpAddress3 -ne "") { $yelpFullAddress += (" " + $yelpAddress3) }
            if ($yelpCity -ne "") { $yelpFullAddress += (" " + $yelpCity) }
            if ($yelpState -ne "") { $yelpFullAddress += (" " + $yelpState) }
            if ($yelpZip -ne "") { $yelpFullAddress += (" " + $yelpZip) }
            $yelpFullAddress
        }
        $yelpResultsCategory0 = foreach ($yelpResult in $yelpResults) {
            $yelpResult.categories[0] | Select-Object -ExpandProperty Title
        }
        $yelpResultsCategory1 = foreach ($yelpResult in $yelpResults) {
            $yelpResult.categories[1] | Select-Object -ExpandProperty Title
        }
        $yelpResultsCategory2 = foreach ($yelpResult in $yelpResults) {
            $yelpResult.categories[2] | Select-Object -ExpandProperty Title
        }
        $yelpResultsImageUrl = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty image_url
        }
        $yelpResultsIsClosed = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty is_closed
        }
        $yelpResultsUrl = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty url
        }
        $yelpResultsReviewCt = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty review_count
        }
        $yelpResultsRating = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty rating
        }
        $yelpResultsPrice = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty price
        }
        $yelpResultsPhone = foreach ($yelpResult in $yelpResults) {
            $yelpResult | Select-Object -ExpandProperty display_phone
        }
        # Create array for proper JSON payload format
        $yelpResultsFiltered = @($yelpResultsId,$yelpResultsAlias,$yelpResultsName,$yelpResultsAddress,$yelpResultsCategory0,$yelpResultsCategory1,$yelpResultsCategory2,$yelpResultsImageUrl,$yelpResultsIsClosed,$yelpResultsUrl,$yelpResultsReviewCt,$yelpResultsRating,$yelpResultsPrice,$yelpResultsPhone)
        Write-Host "Yelp data filtered and formatted.`n"
    }
    catch { Write-Host "Formatting Yelp data for JSON failed." }
}
catch { Write-Host "Connection to Yelp API failed." }
