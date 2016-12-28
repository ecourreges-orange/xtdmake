#!/usr/bin/python

import sys
import os
import json
import argparse
import xml.etree.ElementTree as ET

l_parser = argparse.ArgumentParser()
l_parser.add_argument("--input-file",   action="store", help ="path to xml results",                          required=True)
l_parser.add_argument("--output-file",  action="store", help ="destination output file",                      required=True)
l_parser.add_argument("--min-percent",  action="store", help ="minimum percentage of comments for success",   default=0, type=int)
l_result = l_parser.parse_args()

l_tree = ET.parse(l_result.input_file)
l_data = l_tree.findall("./languages/total")[0]
l_comment  = float(l_data.get("comment"))
l_code     = float(l_data.get("code"))

l_percent  = l_comment / (l_code + l_comment)
l_percent  = int(l_percent * 100.0)

if l_result.output_file == "-":
  l_out = sys.stdout
else:
  l_out = open(l_result.output_file, "w")

  
l_status  = "success"
l_label   = "%d %%" % l_percent

if l_result.min_percent != 0:
  if int(l_percent) <  int(l_result.min_percent):
    l_status = "failure"
  
l_out.write(json.dumps({
  "status" : l_status,
  "label"  : l_label,
  "graphs" : [
        {
      "type"   : "line",
      "data"   : {
        "labels"   : [],
        "datasets" : [
          {
            "yAxisID" : "absolute",
            "label"   : "comment lines",
            "data"    : "%(comment)d",
            "borderColor" : "rgba(51, 204, 51, 0.5)",
            "backgroundColor" : "rgba(51, 204, 51, 0)",
            "pointBorderColor" : "rgba(31, 122, 31, 1)",
            "pointBackgroundColor" : "rgba(31, 122, 31, 1)"
          },
          {
            "yAxisID" : "absolute",
            "label"   : "code lines",
            "data"    : "%(code)d",
            "borderColor" : "rgba(179, 0, 0, 0.5)",
            "backgroundColor" : "rgba(179, 0, 0, 0)",
            "pointBorderColor" : "rgba(102, 0, 0, 1)",
            "pointBackgroundColor" : "rgba(102, 0, 0, 1)"
          },
          {
            "yAxisID" : "percent",
            "label"   : "% comment lines",
            "data"    : "int(float(%(comment)d) / (float(%(comment)d) + float(%(code)d)) * 100)",
            "borderColor" : "rgba(102, 153, 255, 0.5)",
            "backgroundColor" : "rgba(102, 153, 255, 0)",
            "pointBorderColor" : "rgba(0, 60, 179, 1)",
            "pointBackgroundColor" : "rgba(0, 60, 179, 1)"
          }
        ]
      },
      "options" : {
        "title" : {
          "text" : "%(module)s : cloc",
          "display" : True
        },
        "scales" : {
          "xAxes" : [{
            "ticks" : {
              "minRotation" : 80,
              "fontSize": 12
            }
          }],
          "yAxes" : [
            {
              "id"     : "absolute",
              "type"     : "linear",
              "position" : "left",
              "display": True,
              "ticks": {
                "beginAtZero": True,
                "fontSize" : 24
              }
            },
            {
              "id"     : "percent",
              "type"     : "linear",
              "position" : "right",
              "ticks": {
                "beginAtZero" : True,
                "fontSize"    : 24,
                "max"         : 100
              }
            }
          ]
        }
      }
    }
  ],
  "data" : {
    "code"    : int(l_code),
    "comment" : int(l_comment)
  }
}, indent=2))

# Local Variables:
# ispell-local-dictionary: "american"
# End: