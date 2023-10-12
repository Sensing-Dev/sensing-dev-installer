# parse_config.py
import yaml
import argparse

VALID_ACTIONS = ['build', 'download', 'use_existing']

def parse_arguments():
    parser = argparse.ArgumentParser(description="Parse a YAML config to get library details.")
    
    # Define the command-line options
    parser.add_argument("--name", required=True, help="Name of the library in the config.")
    parser.add_argument("--action", default=None,choices=VALID_ACTIONS, help="Desired action. If not provided, it will default to the action specified in the config.")
    parser.add_argument("--config-path", required=True, help="Path to the YAML configuration file.")
    
    return parser.parse_args()

def main():
    args = parse_arguments()
    library_name = args.name
    desired_action = args.action
    config_path = args.config_path

    with open(config_path, 'r') as file:
        # print(f"file : {file}")
        config = yaml.safe_load(file)
        
        if library_name not in config['libraries']:
            print(f"No library named {library_name} found in {config_path}")
            return
        library = config['libraries'][library_name]

        # If the action is not provided via command line, fetch it from the config
        if  desired_action:
            library["action"] = desired_action
        
        print(library.get("name"))
        print(library.get("src_path"))
        print(library.get("install_path"))
        print(library.get("action"))
        print(library.get("pkg_url"))
        print(library.get("pkg_sha"))
        print(library.get("git_repo"))
        print(library.get("version"))
        
if __name__ == "__main__":
    main()
