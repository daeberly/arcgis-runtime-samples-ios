#!/usr/bin/env python3

import os
import re
import json
import plistlib
import argparse
from typing import List


# region Global sets
# A set of category folder names in current sample viewer.
categories = {
    'Maps',
    'Layers',
    'Features',
    'Display information',
    'Search',
    'Edit data',
    'Geometry',
    'Route and directions',
    'Analysis',
    'Cloud and portal',
    'Scenes',
    'Utility network',
    'Augmented reality'
}

excluded_samples = {
    'Map loaded',
    'Animate 3D graphic',
    'Densify and generalize',
    'Add graphics with renderer'
}
# endregion


# region Static functions
def sub_special_char(string: str) -> str:
    """
    Check and substitute if a string contains special characters.

    :param string: The input string.
    :return: A new string without special characters.
    """
    # regex = re.compile('[@_!#$%^&*()<>?/\\|}{~:]')
    regex = re.compile('[@_!#$%^&*<>?|/\\}{~:]')
    return re.sub(regex, '', string)


def get_plist_cat_mapping(plist_category: str) -> str:
    """
    Get the mapping between plist categories and the ones on website.

    :param plist_category: The category in `ContentPlist.plist`.
    :return: The category in `README.metadata.json` files, which also defines
             the online categories on
             https://developers.arcgis.com/ios/latest/swift/sample-code/
    """
    plist_json_categories_mapping = {
        'Maps': 'Maps',
        'Layers': 'Layers',
        'Features': 'Features',
        'Display Information': 'Display information',
        'Search': 'Search',
        'Edit Data': 'Edit data',
        'Geometry': 'Geometry',
        'Route & Directions': 'Route and directions',
        'Analysis': 'Analysis',
        'Cloud & Portal': 'Cloud and portal',
        'Scenes': 'Scenes',
        'Utility Network': 'Utility network',
        'Augmented Reality': 'Augmented reality'
    }
    return plist_json_categories_mapping.get(plist_category)


def load_plist(plist_path: str) -> List[dict]:
    """
    Open a plist file.

    :param plist_path: The path to plist file.
    :return: The plist dictionary. In our particular case is a list of dicts.
    """
    with open(plist_path, 'rb') as fp:
        plist = plistlib.load(fp)
        return plist


def get_plist_categories(plist: List[dict]) -> List[str]:
    """
    A helper function to get all categories in our plist.

    :param plist: The plist dictionary.
    :return: A list of categories.
    """
    plist_categories = [cat.get('displayName') for cat in plist]
    return plist_categories


def get_folder_name_from_path(path: str, index: int = -1) -> str:
    """
    Get the folder name from a full path.

    :param path: A string of a full/absolute path to a folder.
    :param index: The index of path parts. Default to -1 to get the most
    trailing folder in the path; set to certain index to get other parts.
    :return: The folder name.
    """
    return os.path.normpath(path).split(os.path.sep)[index]


def get_readme_description(head_string: str) -> str:
    """
    Parse the head of README and get description.

    :param head_string: A string containing title, description and images.
    :return: Stripped description string.
    """
    # Split title section and rule out empty lines.
    parts = list(filter(bool, head_string.splitlines()))
    if len(parts) < 3:
        raise Exception('README should contain title, description and image.')
    description = parts[1].strip()
    return description


def get_first_sentence(s: str) -> str:
    """
    Return the first sentence separated by period in a string.

    :param s: A string.
    :return: A sentence.
    """
    return sub_special_char(s.split('.')[0] + '.')
# endregion


class Sample:
    def __init__(self, folder_path: str):
        """
        Given a folder path of a sample, get everything we need to compare.
        - Descriptions
          - sample’s plist description
          - sample’s `README.md` description
          - `README.metadata.json` description

        :param folder_path: The path to a sample's folder.
        """
        self.folder_path = folder_path
        self.folder_name = get_folder_name_from_path(folder_path)
        self.folder_category = get_folder_name_from_path(folder_path, -2)

        self.json_description = self.get_json_description()
        self.readme_description = self.get_readme_description()

    def get_json_description(self) -> str:
        json_path = os.path.join(self.folder_path, 'README.metadata.json')
        try:
            json_file = open(json_path, 'r')
            json_data = json.load(json_file)
        except Exception as err:
            print(f'Error reading JSON - {self.folder_name} - {err}')
            raise err
        else:
            json_file.close()
        return json_data['description']

    def get_readme_description(self):
        readme_path = os.path.join(self.folder_path, 'README.md')
        try:
            readme_file = open(readme_path, 'r')
            # read the readme content into a string
            readme_contents = readme_file.read()
        except Exception as err:
            print(f'Error reading README - {self.folder_name} - {err}.')
            raise err
        else:
            readme_file.close()
        pattern = re.compile(r'^#{2}(?!#)\s(.*)', re.MULTILINE)
        readme_parts = re.split(pattern, readme_contents)
        return get_readme_description(readme_parts[0])


# region Main wrapper functions
def single_sample_check_diff(folder_path: str, plist: List[dict]):
    sample = Sample(folder_path)
    if sample.folder_name in excluded_samples:
        # Deliberately omit a few samples.
        return
    # Get category for a sample
    plist_cats = list(
        filter(lambda d: get_plist_cat_mapping(d.get('displayName')) ==
               sample.folder_category, plist))
    # Get the children, a list of sample dicts.
    plist_children: List[dict] = plist_cats[0].get('children')
    # Get sample item dictionary.
    plist_names = list(
        filter(lambda d: d.get('displayName') == sample.folder_name,
               plist_children))
    plist_description = plist_names[0].get('descriptionText')

    err_count = 0
    p = plist_description
    # Check if plist description matches sample README description.
    r = sample.readme_description
    if p != r and p != get_first_sentence(r):
        err_count += 1
        print(f'  {err_count}. plist "{p}" does not match'
              f' README description "{r}".')
    # Check if plist description matches sample json.description.
    j = sample.json_description
    if p != j and p != get_first_sentence(j):
        err_count += 1
        print(f'  {err_count}. plist "{p}" does not match'
              f' json.description "{j}".')

    if err_count > 0:
        raise Exception(f'{err_count} error(s) occurred during checking '
                        f'/{sample.folder_category} - {sample.folder_name}.')


def all_samples(path: str, plist: List[dict]):
    """
    Run the check on all samples.

    :param path: The path to 'arcgis-ios-sdk-samples' folder.
    :param plist: The plist dictionary. In our case is a list of dicts.
    :return: None. Throws if exception occurs.
    """
    exception_count = 0
    for root, dirs, files in os.walk(path):
        # Get parent folder name.
        parent_folder_name = get_folder_name_from_path(root)
        # If parent folder name is a valid category name.
        if parent_folder_name in categories:
            for dir_name in dirs:
                sample_path = os.path.join(root, dir_name)
                # Omit empty folders - they are omitted by Git.
                if len([f for f in os.listdir(sample_path)
                        if not f.startswith('.DS_Store')]) == 0:
                    continue
                try:
                    single_sample(sample_path, plist)
                except Exception as err:
                    exception_count += 1
                    print(f'{exception_count}. {err}')

    # Throw once if there are exceptions.
    if exception_count > 0:
        raise Exception('Error(s) occurred during checking all samples.')


def single_sample(path: str, plist: List[dict]):
    """
    Run the check on a single sample.

    :param path: The path to a sample's folder.
    :param plist: The plist dictionary. In our case is a list of dicts.
    :return: None. Throws if exception occurs.
    """
    try:
        single_sample_check_diff(path, plist)
    except Exception as err:
        raise err


def main():
    msg = 'Description checker script. Run it against the ' \
          '/arcgis-ios-sdk-samples folder or a single sample folder. ' \
          'On success: Script will exit with zero. ' \
          'On failure: Description inconsistency will print to console and ' \
          'the script will exit with non-zero code.'
    parser = argparse.ArgumentParser(description=msg)
    parser.add_argument('-a', '--all', help='path to arcgis-ios-sdk-samples '
                                            'folder')
    parser.add_argument('-s', '--single', help='path to single sample folder.')
    args = parser.parse_args()

    if args.all:
        # Load ContentPList.plist.
        plist_path = os.path.normpath(
            args.all + '/Content Display Logic/ContentPList.plist')
        plist = load_plist(plist_path)
        if not plist:
            raise Exception('Error loading plist.')

        try:
            all_samples(args.all, plist)
        except Exception as err:
            raise err
    elif args.single:
        # Load ContentPList.plist.
        plist_path = os.path.normpath(
            args.single + '/../../Content Display Logic/ContentPList.plist')
        plist = load_plist(plist_path)
        if not plist:
            raise Exception('Error loading plist.')

        try:
            single_sample(args.single, plist)
        except Exception as err:
            raise err
    else:
        raise Exception('Invalid arguments, abort.')
# endregion


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'{error}')
        exit(1)
