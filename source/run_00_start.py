import sys
import time
import config
import pathlib
import selenium
import selenium.webdriver
import selenium.webdriver.common
import selenium.webdriver.common.keys
import selenium.webdriver.common.action_chains
import selenium.webdriver.support
import selenium.webdriver.support.ui
import selenium.webdriver.support.wait
import selenium.webdriver.support.expected_conditions
import pyperclip
import subprocess
class SeleniumMixin(object):
    def __init__(self):
        self._driver=selenium.webdriver.Firefox()
        self._wait=selenium.webdriver.support.wait.WebDriverWait(self._driver, 2)
    def sel(self, css):
        log("sel css={}".format(css))
        return self._driver.find_element_by_css_selector(css)
    def selx(self, xpath):
        log("sel xpath={}".format(xpath))
        return self._driver.find_element_by_xpath(xpath)
    def wait_css_clickable(self, css):
        self._wait.until(selenium.webdriver.support.expected_conditions.element_to_be_clickable((selenium.webdriver.common.by.By.CSS_SELECTOR,css,)))
    def wait_css_gone(self, css):
        self._wait.until(selenium.webdriver.support.expected_conditions.invisibility_of_element_located((selenium.webdriver.common.by.By.CSS_SELECTOR,css,)))
    def wait_css_clickable(self, css):
        self._wait.until(selenium.webdriver.support.expected_conditions.element_to_be_clickable((selenium.webdriver.common.by.By.CSS_SELECTOR,css,)))
    def wait_xpath_clickable(self, xpath):
        self._wait.until(selenium.webdriver.support.expected_conditions.element_to_be_clickable((selenium.webdriver.common.by.By.XPATH,xpath,)))
    def waitsel(self, css):
        self.wait_css_clickable(css)
        return self.sel(css)
    def waitselx(self, xpath):
        self.wait_xpath_clickable(xpath)
        return self.selx(xpath)
def current_milli_time():
    return int(round(((1000)*(time.time()))))
global g_last_timestamp
g_last_timestamp=current_milli_time()
def milli_since_last():
    global g_last_timestamp
    current_time=current_milli_time()
    res=((current_time)-(g_last_timestamp))
    g_last_timestamp=current_time
    return res
class bcolors():
    OKGREEN="\033[92m"
    WARNING="\033[93m"
    FAIL="\033[91m"
    ENDC="\033[0m"
def log(msg):
    print(((bcolors.OKGREEN)+("{:8d} LOG ".format(milli_since_last()))+(msg)+(bcolors.ENDC)))
    sys.stdout.flush()
def fail(msg):
    print(((bcolors.FAIL)+("{:8d} FAIL ".format(milli_since_last()))+(msg)+(bcolors.ENDC)))
    sys.stdout.flush()
def warn(msg):
    print(((bcolors.WARNING)+("{:8d} WARNING ".format(milli_since_last()))+(msg)+(bcolors.ENDC)))
    sys.stdout.flush()