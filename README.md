# Moov Swimming Data Toolkit

This R package provides functions for reading data out of MOOV sensors. Currently supports only data from swimming sessions.

## Retrieving Moov data

To use this package, you first need to retrieve data from Moov that is stored in your device.
We will need the file `user.db` and the folder `swimming`. Both of them are stored in 
`/Applications/moov.core/Library/Application Support/user_data/( user id )/`.

__iOS:__ Use [iExplorer](https://macroplant.com/iexplorer) (the free version is OK) to browse your iOS device backup.

__Android:__ See the instruction in [Marin's code](https://github.com/hoffoo/moov-csv).


## Usage

Install and load the package:

```r
devtools::install_github("chatchavan/Moov")
library(Moov)
```

See an example [here](https://chatchavan.github.io/Moov/read_and_plot.html)

## Structure of Moov data

The `user.db` file is an SQLite database containing summary data for each sesssion.
There are sub-folder inside the `swimming\(some number)\`  for each session. 
Each of these folders contains three files:
  
  * `swimming_result.pb`: A binary file containing sensor data from that session. (More on this below.)
  * `swimming_post_analysis_result.pb`: A binary file. Probably contain summary of that session , e.g., the number of strokes in each lap. I haven't managed to parse this.
  * `swimming_result.pb.uploaded`: always zero bytes. I suspect this is a marker file indicating that the data is uploaded to the server

### `swimming_result.pb`

Most of this file is the sensor data. Before you can get to the data, you need to 
extract them from the header and trim out the tail. The actual sensor data seems 
to be prefixed by one of the following byte sequences:

```
older files: 0900 0000 0000 0000 0011 FFFF B0B4 48FC 0341 9A01
newer files: 0108 0C10 6018 0320 0A2A
```

Each frame of the sensor data seems to be 2 bytes. I read them as integer and plot
the values over the number of frame. The periodical structure seems to mimic
swimming pattern. (Strokes and laps are visible in the plot.)

The end of each file is tailed with a bunch of `FFFF` bytes.


### `user.db`

Here's an example record from `user.db`:

```
- id: "1"
- session_id: "swimming-xj9p6a2uzi8u010jmwpjyc2"
- user_id: "6234565289443328"
- title: "Afternoon Swim"
- workout_type: "2"
- program: "0"
- calories: "442.163146972656"
- location_text: ""
- location_long: "0.0"
- location_lat: "0.0"
- start_time: "1461945492"
- end_time: "1461948928"
- duration: "3394"
- magnitude: "1900.0"
- summary: ""
- highlight_type: "0"
- highlight_text: ""
- status: "1"
- upload_status: "3"
- created_at: "1465396302"
- updated_at: "1495716980"
- server_updated_at: "1495713919"
- env_info: "{""app_build"": ""3.11.910.160"", ""app_name"": ""moov.core"", ""app_version"": ""160"", ""devices"": [], ""gps_enabled"": true, ""phone_model"": ""iPhone8,1"", ""phone_os_version"": ""9.3.1""}"
- program_specific_data: "{""lap_count"": 38, ""lap_length_in_lap_unit"": 50, ""lap_unit"": 0, ""stroke_count"": 905, ""user_height"": 1.7599999904632568, ""user_weight"": 69}"
- local_cache: "{""distance"": 1950, ""distance_per_stroke"": 2.1546962261199951, ""lap_length"": 50, ""stroke_rate"": 2.018596887588501, ""version"": 3}"
	- Key names are changed from record 115 onward
	
	- This field is NULL for the last 6 records
	- The "distance_per_stroke" doesn't match with "magnitude / stroke_count"
```

* `workout_type`: always "2" for swimming.
* `calories`: in kCal
* `duration`: Swimming duration in seconds. This matches what shown on the MOOV summary screen This is not necessarily less than "end_time - start_time"
* `magnitude`: The total distance in meters
* `local_cache`: JSON data with some performance metric calculation
   * This field is NA from recent records
   * The new version of the file, the name of some fields are changed:
      - `distance_per_stroke` → `main_distance_per_stroke`
		  - `stroke_rate` → `main_stroke_rate`


## Tested sensors

* [Moov Motion Sensor (Moov Classic)](https://moov.zendesk.com/hc/en-us/articles/231668827-What-are-Moov-Classic-s-technical-specifications-tech-specs-)