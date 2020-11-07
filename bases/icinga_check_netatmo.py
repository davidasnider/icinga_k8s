#!/usr/bin/python3

from argparse import ArgumentParser
import requests

# import sys

client_id = "thisisnottherealclientid"  # pragma: allowlist secret
client_secret = "thisisnottherealclientsecret"  # pragma: allowlist secret
username = "thisisnottherealusername"  # pragma: allowlist secret
password = "thisisnottherealpassword"  # pragma: allowlist secret
device_id = "70:ee:50:03:81:2e"


# def checkResponse(r):
#     """
#     Quick logic to check the http response code.

#     Parameters:
#             r = http response object.
#     """

#     acceptedResponses = [200, 201, 203, 204]
#     if r.status_code not in acceptedResponses:
#         print("STATUS: ", r.status_code)
#         print("ERROR: ", r.text)
#         sys.exit(r.status_code)


def create_cli_parser():
    """
    Creates a command line interface parser.
    """

    cli_parser = ArgumentParser(description=__doc__)

    # Add the CLI options
    cli_parser.add_argument(
        "--device",
        action="store",
        help="Whats the name of the device to check?",
        default=False,
    )
    return cli_parser


def nagios_return(device, reachable):
    print(device, "is reachable: ", reachable)
    if reachable is True:
        exit(0)
    else:
        exit(2)


# Create the command line parser.
cli_parser = create_cli_parser()

# Get the options and arguments.
args = cli_parser.parse_args()

# Let's get an access code
payload = {
    "grant_type": "password",
    "username": username,
    "password": password,
    "client_id": client_id,
    "client_secret": client_secret,
    "scope": "read_station",
}
try:
    response = requests.post("https://api.netatmo.com/oauth2/token", data=payload)
    response.raise_for_status()
    access_token = response.json()["access_token"]
    # refresh_token = response.json()["refresh_token"]
    # scope = response.json()["scope"]
except requests.exceptions.HTTPError as error:
    print(error.response.status_code, error.response.text)

# Let's get information from our station
params = {"access_token": access_token, "device_id": device_id}

try:
    response = requests.post(
        "https://api.netatmo.com/api/getstationsdata", params=params
    )
    response.raise_for_status()
    data = response.json()["body"]
except requests.exceptions.HTTPError as error:
    print(error.response.status_code, error.response.text)

for device in data["devices"]:
    device_name = device["module_name"]
    if args.device == device_name:
        nagios_return(device_name, device["reachable"])
    else:
        # Loop through the modules
        for module in device["modules"]:
            module_name = module["module_name"]
            if args.device == module_name:
                nagios_return(module_name, module["reachable"])

# If we got here, we found no devices.  Exit with error code 3
print(args.device, "appears to be an incorrect device name")
exit(3)
