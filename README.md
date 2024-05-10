# Scalper

This project's purpose is to crawl a collection of shop websites to know if a product is available
to buy on any of this site.

How does it work?

- it reads a list of URLs from a Google spreadsheet (column C)
- for each of these URLs it performs an HTTP GET query and performs a negative search based on the
  column D from the spreadsheet: if the text is present, then the product is unavailable
- then it updates the spreadsheet with availability results.

## Installation

### Google Spreadsheet setup

- create a new spreadsheet and list URLs in the col C and the negative search text in col D
- create a new project in [Google Developper console](https://console.cloud.google.com/)
- in this project create a service account and download the keys as a JSON file
- go back on your spreadsheet, click on the Share button, and authorize your service account's email
  to modify the document

### Environment variables

The following variables should be available in your shell environment before running scalper:

- `SPREADSHEET_ID` the id of the spreadsheet (present in your spreadsheet URL)
- `GOOGLE_PRIVATE_KEY` present in the service account keys json file
- `GOOGLE_CLIENT_EMAIL` present in the service account keys json file

### Install Elixir

Documentation available [here](https://elixir-lang.org/install.html).

### Install scalper dependencies

```
mix deps.get
```

### Run the scalper

```
mix scalper
```

or if you want to run it indefintely every 5 mn

```
mix scalper 5
```
