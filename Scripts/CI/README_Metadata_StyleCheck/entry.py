# Copyright 2020 Esri.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import argparse
import subprocess as sp
from os import listdir
from os.path import isfile, join
import json

# Example usage:
# python3 entry.py -s root/path/to/sample/README.md
# python3 entry.py -s root/path/to/sample/README.md,root/path/to/sample/readme.metadata.json
# python3 entry.py -s "[root/path/to/sample/README.md, root/path/to/sample/readme.metadata.json]"

def main():
    msg = 'Entry point of the docker to run json style check scripts.'
    parser = argparse.ArgumentParser(description=msg)
    parser.add_argument('-s', '--string', help='A list of comma separated values')
    try:
        args = parser.parse_args()
        cleanstring = ""
        for letter in args.string:
            if letter not in '[" \']':
                cleanstring+=letter
        file_list = cleanstring.split(",")
    except Exception as e:
        print(f"Unable to parse arguments. Either there are no arguments or the directory structure may have errors.\nException: {e}")
        exit(1)
    check_files(file_list)
    
def check_files(file_list):
    total_errors = 0
    tests = 0
    if not file_list:
        # This will trigger if the GitHub action is somehow triggered, but no files were changed,
        # so no files will be present to check. This scenario is unlikely.
        print("No files in file set")
        exit(0)

    for file in file_list:
        if not file:
            # This will trigger if extra commas are included in the input string
            continue
        try:
            errors = []
            # Set variables for file
            directory_list = file.split("/")
            file_name = directory_list[-1]
            
            # Check skip file conditions
            # Does the file exist, is it in a category, is it a .json or .md?
            if not is_file_valid(directory_list):
                continue
            
            tests += 1
            # If metadata file
            if file_name.lower() == 'readme.metadata.json':
                try:
                    json_file = MetadataFile(file)
                    errors += json_file.check_metadata_file_for_errors()
                except Exception as e:
                    errors.append(f"Error checking {file}. Exception: {e}")

            # If README.md
            elif file_name.lower() == 'readme.md':
                try:
                    readme_file = READMEFile(file)
                    errors += readme_file.check_readme_for_errors()
                except Exception as e:
                    errors.append(f"Error checking {file}. Exception: {e}")
            
            # Count and print the errors
            if len(errors) > 0:
                print(f"Found {len(errors)} errors in file:\n{file}")
                for i in range(len(errors)):
                    print(f"{i+1}. {errors[i]}")
                print("\n")
            total_errors += len(errors)
        except Exception as e:
            print(f"Critical failure on file: {file}. You may need to use a full file path rather than a relative path. Exception: {e}")
            total_errors += 1
    
    if tests == 0:
        print("No files were tested.")
        exit(0)
    if total_errors == 0:
        print("All tests passed!")
    else:
        print(f"Total errors: {total_errors}")
    # When we exit an pass a non-zero value, GitHub registers the test as failed
    exit(total_errors)

def is_file_valid(directory_list: list)-> bool:
    try:
        # directory structure is "folder/category/sample_name/file"
        # If the file is not in a sample category folder, it does not need to be tested
        category_name = directory_list[-3]
        if category_name not in folder_names:
            return False
    except:
        return False
    
    if not os.path.exists("/".join(directory_list)):
        # The file is not present on the disk, either because it never existed or because it was deleted
        # If the file was modified by deleting it, then we do not need to check it
        return False

    if directory_list[-1].lower() not in  ['readme.metadata.json', 'readme.md']:
        # We are not testing files other than the ones above
        return False

    return True

class MetadataFile:
    def __init__(self, file_path):
        self.file_path = file_path
        self.directory_list = file_path.split("/")
        self.file_name = self.directory_list[-1]
        self.folder_path = "/".join(self.directory_list[:-1])
        self.sample_name = self.directory_list[-2]
        self.category_name = self.directory_list[-3]
        self.sample_type = self.directory_list[-4]
        self.other_files_in_folder = get_filenames_in_folder(self.folder_path)
        self.api_list = []
        self.keyword_list = []
        self.metadata = read_json_file(file_path)
        self.metadata_keys = [key for key in self.metadata.keys()]

    def check_metadata_file_for_errors(self):
        self.metadata_errors = []

        # General check for capitalization, ordering, and presence
        if self.file_name != "README.metadata.json":
            self.metadata_errors.append(f"{self.file_name} does not have correct capitalization")

        if not is_subsequence(self.metadata_keys,possible_metadata_keys):
            self.metadata_errors.append(f"JSON keys are not in the correct order\nExpected order is: {possible_metadata_keys}")

        for expected_key in required_metadata_keys:
            if expected_key not in self.metadata_keys:
                self.metadata_errors.append(f"{expected_key} not found in file metadata keys")

        # Check the individual sections by passing each key to check_sections(0)
        for key in self.metadata_keys:
            try:
                self.metadata_errors += (self.check_sections(key))
            except Exception as e:
                self.metadata_errors.append(f"Errors testing: {key}. Exception: {e}")

        return self.metadata_errors

    def check_sections(self, key: str):
        # We do this in case the .json key is not one of the accepted sections
        if key == "category":
            return self.check_category(self.metadata["category"])
        elif key == "dataItems":
            return self.check_data_items(self.metadata["dataItems"])
        elif key == "description":
            return self.check_description(self.metadata["description"])
        elif key == "ignore":
            return self.check_ignore(self.metadata["ignore"])
        elif key == "images":
            return self.check_images(self.metadata["images"])
        elif key == "keywords":
            return self.check_keywords(self.metadata['keywords'])
        elif key == "redirect_from":
            return []
        elif key == "relevant_apis":
            return self.check_relevant_apis(self.metadata['relevant_apis'])
        elif key == "snippets":
            return self.check_snippets(self.metadata["snippets"])
        elif key == "title":
            return self.check_title(self.metadata["title"])
        else:
            return [f"Category: '{key}' is not a recognized readme metadata key."]

    def check_category(self, category: str) -> list:
        if not category:
            return ["No category"]
        errors = []
        if category not in metadata_categories:
            errors.append(f"Category does not match any currently listed metadata categories: ('{category}')")
        if "".join(category.split(" ")).lower() != self.category_name.lower():
            errors.append(f"Category does not match parent category folder: ('{category}' != '{self.category_name}')")
        return errors

    def check_data_items(self, data_items) -> list:
        if not data_items or data_items == []:
            return ["No data items"]
        errors = []
        for i in range(len(data_items)):
            if not data_items[i].get('itemId', None):
                errors.append(f"dataItem {i} needs an itemId")
            if not data_items[i].get('path', None):
                errors.append(f"dataItem {i} needs a path")
        return errors
    
    def check_description(self, description: str) -> list:
        if not description:
            return ["No description written"]
        errors = []
        if description[-1] not in ".?!":
            errors.append("Description does not end in proper punctuation")
        return errors

    def check_ignore(self, ignore) -> list:
        if ignore not in [True, False]:
            return ["Ignore value must be true or false"]
        errors = []
        return errors
    
    def check_images(self, images: list) -> list:
        if not images:
            return ["No images listed"]
        errors = []
        images_in_folder = self.other_files_in_folder
        has_screenshotpng = False
        for image in images:
            if not image in images_in_folder:
                errors.append(f"{image} not found in folder")
            if image == "screenshot.png":
                has_screenshotpng = True
        if not has_screenshotpng:
            errors.append("'screenshot.png' not found")
        return errors

    def check_keywords(self, keywords: list) -> list:
        if not keywords:
            return ["No keywords found"]
        errors = []
        for keyword in keywords:
            if keyword in self.keyword_list:
                errors.append(f"Duplicate keyword: {keyword}")
            else:
                self.keyword_list.append(keyword)
        return errors

    def check_redirect_from(self, redirects: list) -> list:
        if redirects == ['']:
            return ["No redirects listed"]
        errors = []
        has_expected_redirect = False
        expected_redirect = f"/qt/latest/cpp/sample-code/sample-qt-{self.sample_name}.htm"
        for redirect in redirects:
            if redirect.lower() == expected_redirect.lower():
                has_expected_redirect = True
        if not has_expected_redirect:
            errors.append(f"Expected redirect ({expected_redirect}) not found among {redirects}")
        return errors

    def check_relevant_apis(self, apis: list) -> list:
        if not apis:
            return ["No APIs listed"]
        errors = []
        for api in apis:
            if api in self.api_list:
                errors.append(f"Duplicate API: {api}")
            else:
                self.api_list.append(api)
        return errors

    def check_snippets(self, snippets: list) -> list:
        if not snippets:
            return ["No snippets listed"]
        errors = []
        for snippet in snippets:
            if snippet not in self.other_files_in_folder:
                errors.append(f"{snippet} not found in sample folder")
        expected_snippets = [
            self.sample_name + ".qml",
        ]

        if self.sample_type == "ArcGISRuntimeSDKQt_CppSamples":
            expected_snippets += [self.sample_name + ".cpp", self.sample_name + ".h"]

        if not snippets[0] == expected_snippets[0]:
            errors.append(f"The .qml snippet must be listed first in the list.")
            
        for expected_snippet in expected_snippets:
            if expected_snippet not in snippets:
                errors.append(f"Expected {expected_snippet} in snippets")
        return errors

    def check_title(self, title: str) -> list:
        if not title:
            return ["No title"]
        elif not check_sentence_case:
            return ["Title does not follow sentence case"]
        return []

class READMEFile:
    def __init__(self, file_path):
        self.file_path = file_path
        self.directory_list = file_path.split("/")
        self.file_name = self.directory_list[-1]
        self.folder_path = "/".join(self.directory_list[:-1])
        self.sample_name = self.directory_list[-2]
        self.category_name = self.directory_list[-3]
        self.sample_type = self.directory_list[-4]
        self.other_files_in_folder = get_filenames_in_folder(self.folder_path)
        self.api_list = []
        self.tag_list = []
        self.readme_text = read_readme_file(file_path)
        self.title = ""
        self.description = ""
        self.screenshot_text = ""
        self.sections = {}
        self.section_header_list = []

        self.parse_readme()
    
    def parse_readme(self):
        # Split out sections by header 2
        text = self.readme_text.split("\n## ")

        # Parse header
        try:
            header = text.pop(0)
            # This splits the header by the first instance of \n
            # We do this in case description is multiple lines
            header = [header[:header.find("\n")]] + [header[header.find("\n")+1:]]
            self.title = header[0][2:]
            self.description, self.screenshot = header[1].split("\n![]") # This doesn't work if screenshot is formatted improperly.
        except Exception as e:
            return f"Title, description, or screenshot.png formatted incorrectly. README check cannot proceed.\nFatal error: {e}"

        # If all goes well, the only sections remaining in the text begin with h2's (## )
        for section in text:
            section_body = section.split("\n")
            section_title = section_body.pop(0)
            self.section_header_list.append(section_title)
            if section_title in self.sections:
                self.sections[section_title] += section_body
            else:
                self.sections[section_title] = section_body

    def check_readme_for_errors(self) -> list:
        # Some samples don't have a conventional README so they should be skipped.
        if self.sample_name in ignore_samples_READMEs:
            return []
        self.readme_errors = []
        self.readme_errors += (self.check_readme_section_headers())
        self.readme_errors += (self.check_readme_sections())
        return self.readme_errors

    def check_readme_section_headers(self) -> list:
        # Check if missing essential headers
        missing_headers = []
        self.header_errors = []
        
        for essential_header in essential_readme_headers:
            if essential_header not in self.section_header_list:
                missing_headers.append(essential_header)
        
        if missing_headers:
            self.header_errors.append(f"Missing essential headers: {missing_headers}. (This may be due to improper capitalization).")
        
        # Check if README headers are in order
        if not is_subsequence(self.section_header_list, possible_readme_headers):
            self.header_errors.append(f"Section headers are not in the correct order.\nExpected order to be: {possible_readme_headers}.")

        # Check if duplicate headers
        temp_header_list = []
        for header in self.section_header_list:
            if header in temp_header_list:
                self.header_errors.append(f"Header '{header}' is a a duplicate.")
            else:
                temp_header_list.append(header)
        return self.header_errors

    def run_mdl(readme_path: str):
        code = sp.call(f'mdl --style /style.rb "{readme_path}"', shell=True)
        return code

    def check_readme_sections(self) -> list:
        self.section_errors = []
        for header in self.sections.keys():
            if header.lower() == "relevant api":
                self.section_errors += (self.check_relevant_api(header))

            elif header.lower() == "tags":
                self.section_errors += (self.check_tags(header))

            elif header.lower() == "offline data":
                self.section_errors += (self.check_if_section_contents(header))

            elif header in possible_readme_headers:
                self.section_errors += (self.check_if_section_contents(header))
            else:
                self.section_errors += ([f"{header} not found in possible README headers."])
        return self.section_errors

    def check_relevant_api(self, h) -> list:
        if not self.sections[h]:
            return ["No text found in 'Relevant API'"]
        errors = []
        for i in range(len(self.sections[h])):
            if self.sections[h][i][:2] != "* ":
                errors.append(f"Expected unordered list item as '* ' on line {i}")
            else:
                api = self.sections[h][i][2:]
                if api in self.api_list:
                    errors.append(f"{api} is duplicate on line {i}")
                else:
                    self.api_list.append(api)
                    if api in self.tag_list:
                        errors.append(f"{api} should not be in tags")
        if self.api_list != sorted(self.api_list, key=str.casefold):
            errors.append("Expected API list to be sorted alphabetically")
        return errors

    def check_tags(self, h) -> list:
        if not self.sections[h]:
            return ["No tags found in 'Tag' section"]
        errors = []
        tags = self.sections[h][0].split(", ")
        for tag in tags:
            if tag in self.tag_list:
                errors.append(f"Tag '{tag}' has duplicates.")
            else:
                self.tag_list.append(tag)
                if tag in self.api_list:
                    errors.append(f"Tag '{tag}' should not be an API.")
        if self.tag_list != sorted(self.tag_list, key=str.casefold):
            errors.append("Expected tag list to be sorted alphabetically")
        return errors

    def check_if_section_contents(self, h) -> list:
        if not self.sections[h]:
            return [f"No text found in {h} section body."]
        errors = []
        return errors

# ***** Large variable sets (from utilities.common_dicts) *****

folder_names = [
    'Analysis',
    'AR',
    'CloudAndPortal',
    'DisplayInformation',
    'EditData',
    'Features',
    'Geometry',
    'Layers',
    'LocalServer',
    'Maps',
    'Routing',
    'Scenes',
    'Search',
    'UtilityNetwork'
]

metadata_categories = [
    'Analysis',
    'AR',
    'Cloud and portal',
    'Display information',
    'Edit data',
    'Features',
    'Geometry',
    'Layers',
    'Local Server',
    'Maps',
    'Routing',
    'Scenes',
    'Search',
    'Utility network'
]

required_metadata_keys = [
    'category',
    'description',
    'ignore',
    'images',
    'keywords',
    'redirect_from',
    'relevant_apis',
    'snippets',
    'title'
]

possible_metadata_keys = [
    'category',
    'dataItems',
    'description',
    'ignore',
    'images',
    'keywords',
    'redirect_from',
    'relevant_apis',
    'snippets',
    'title'
]

essential_readme_headers = [
    'Use case',
    'How to use the sample',
    'How it works',
    'Relevant API',
    'Tags'
]

possible_readme_headers = [
    'Use case',
    'How to use the sample',
    'How it works',
    'Relevant API',
    'Offline data',
    'About the data',
    'Additional information',
    'Tags'
]

ignore_samples_READMEs = [
    'OAuthRedirectExample'
]

# ***** HELPER FUNCTIONS

def read_json_file(file_path):
    data = None
    with open(file_path) as file:
        data = json.load(file)
    return data

def read_readme_file(file_path):
    readme_text = ""
    with open(file_path, 'r') as f:
        data = f.readlines()
        # Remove blank lines
        for line in data:
            if line != "\n":
                readme_text += line
    return readme_text

def check_sentence_case(string: str) -> bool:
    ignore_list = {
        "3D",
        "ArcGIS"
    }
    alnum_string = filter_string_for_alpha_numeric(string)
    words = alnum_string.split(" ")
    i = 0
    while i < len(words):
        if words[i] in ignore_list or words[i][0] == "`":
            continue
        j = 0
        starting_letter = 0
        while j < len(words[i]):
            if not words[i][j].isalpha():
                starting_letter += 1
            elif i == 0 and j == starting_letter:
                if not words[i][j].isupper():
                    return False
            elif not words[i][j].islower():
                return False
            j += 1
        i += 1
    return True

def get_filenames_in_folder(folderpath):
    return [file for file in listdir(folderpath) if isfile(join(folderpath, file))]

def is_subsequence(arr1, arr2) -> bool:
    if len(arr1) > len(arr2) or not arr1:
        return False
    i, j = 0, 0
    while i < len(arr1) and j < len(arr2):
        if arr1[i].lower() == arr2[j].lower():
            i += 1
        j += 1
    if i == len(arr1):
        return True
    return False

def filter_string_for_alpha_numeric(string):
    clean_string = ""
    for letter in string:
        if letter.isalnum() or letter in " `":
             clean_string += letter
    return clean_string

if __name__ == '__main__':
    main()
