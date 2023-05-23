
# LineageOS Build Script for OnePlus Nord N200 5G (codenamed Dre)

This script automates the process of building the latest version of LineageOS for the OnePlus Nord N200 5G (codenamed Dre). It streamlines the setup, configuration, and build steps, making it easier for developers and enthusiasts to compile their custom ROM.

## Features

- Automates the setup and initialization of the LineageOS source repository
- Optimizes network configuration for faster downloads and builds
- Installs missing dependencies required for building Lineage eon
- Configures DNS settings for optimal performance
- Provides options to enable Google's DNS configuration
- Clones the necessary device-specific and vendor repositories
- Enables ccache for faster subsequent builds
- Sets up environment variables for the build
- Notifies the user with visual and auditory feedback upon build completion
- Provides an option to revert all changes made by the script

## Usage

1. Ensure that you are running Ubuntu.
2. Clone this repository to your local machine.
3. Make the script executable: `chmod +x build-lineage.sh`.
4. Run the script: `./build-lineage.sh`.
5. Follow the prompts and wait for the build process to complete.

**Note: Do not commit directly to the main branch.**

## Contributing

This project welcomes contributions from the community! However, please only commit your changes to the `testing` branch. The `testing` branch serves as the community branch, and the stable code will be manually ported over to the `main` branch when time permits.

To contribute:

1. Fork this repository and create a new branch based on the `testing` branch.
2. Make your desired changes, following the instructions provided.
3. Submit a pull request from your branch to the `testing` branch of this repository.
4. Please ensure that your code adheres to the established coding conventions and follows the instructions provided.

If your pull request is denied, it may be because the instructions were not followed correctly. You are welcome to resubmit your code after following the instructions properly.

## Disclaimer

This script is provided as-is without any warranties or guarantees. Use it at your own risk. Always ensure you have the necessary knowledge and backup your data before proceeding with any system modifications.

## License

This project is licensed under the [GNU General Public License v2.0](LICENSE).
