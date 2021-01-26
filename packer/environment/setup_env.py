#!/usr/bin/env python3

import os
import crypt
import logging
import argparse

# Define logger for cross appliction logging consistency
logger = logging.getLogger(__name__)

# Create custom logging class for exceptions
class OneLineExceptionFormatter(logging.Formatter):
    def formatException(self, exc_info):
        result = super().formatException(exc_info)
        return repr(result)
 
    def format(self, record):
        result = super().format(record)
        if record.exc_text:
            result = result.replace("\n", "")
        return result

def main():
    '''Main function to set passwords for environment
    '''

    parser = argparse.ArgumentParser(description="Use this script to configure your vSphere environment.")
    parser.add_argument("-p", "--prompt", action="store", dest="prompt",
                        help="Use this argument to be prompted for all required environment settings",
                        required=False)
    parser.add_argument("-e", "--env", action="store", dest="env",
                        help="Location of environment.py file - default vaule is the current directory.",
                        default="environment.py", required=True)
    parser.add_help()

if __name__ == "__main__":
    try:
        exit(main())
    except Exception:
        logging.exception("Exception in main()")
        exit(1)