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
import pandas as pd
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
class SeleniumMixin(object):
    def __init__(self):
        log("SeleniumMixin::__init__")
        profile=selenium.webdriver.FirefoxProfile()
        profile.set_preference("permissions.default.image", 2)
        self._driver=selenium.webdriver.Firefox()
        self._wait=selenium.webdriver.support.wait.WebDriverWait(self._driver, 5)
        log("SeleniumMixin::__init__ finished")
    def sel(self, css):
        log("sel css={}".format(css))
        return self._driver.find_element_by_css_selector(css)
    def sels(self, css):
        log("sels css={}".format(css))
        return self._driver.find_elements_by_css_selector(css)
    def selx(self, xpath):
        log("sel xpath={}".format(xpath))
        return self._driver.find_element_by_xpath(xpath)
    def selxs(self, xpath):
        log("sel xpath={}".format(xpath))
        return self._driver.find_elements_by_xpath(xpath)
    def wait_css_gone(self, css):
        log("wait gone css={}".format(css))
        self._wait.until(selenium.webdriver.support.expected_conditions.invisibility_of_element_located((selenium.webdriver.common.by.By.CSS_SELECTOR,css,)))
    def wait_css_clickable(self, css):
        self._wait.until(selenium.webdriver.support.expected_conditions.element_to_be_clickable((selenium.webdriver.common.by.By.CSS_SELECTOR,css,)))
    def wait_xpath_gone(self, xpath):
        log("wait gone xpath={}".format(xpath))
        self._wait.until(selenium.webdriver.support.expected_conditions.invisibility_of_element_located((selenium.webdriver.common.by.By.XPATH,xpath,)))
    def wait_xpath_clickable(self, xpath):
        log("wait clickable xpath={}".format(xpath))
        self._wait.until(selenium.webdriver.support.expected_conditions.element_to_be_clickable((selenium.webdriver.common.by.By.XPATH,xpath,)))
    def waitsel(self, css):
        self.wait_css_clickable(css)
        return self.sel(css)
    def waitselx(self, xpath):
        self.wait_xpath_clickable(xpath)
        return self.selx(xpath)
    def current_scroll_height(self):
        h=self._driver.execute_script("return document.body.scrollHeight")
        log("scroll_height={}".format(h))
        return h
    def current_client_height(self):
        h=self._driver.execute_script("return document.body.clientHeight")
        log("client_height={}".format(h))
        return h
    def incrementally_scroll_down(self, pause_time=(2.0000000298023224e-1)):
        last_height=self.current_scroll_height()
        while (True):
            self._driver.execute_script("window.scrollTo(0, {});".format(((last_height)+(self.current_client_height()))))
            time.sleep(pause_time)
            new_height=self.current_scroll_height()
            if ( ((new_height)==(last_height)) ):
                log("reached end of page.")
                break
            last_height=new_height
class LinkedIn(SeleniumMixin):
    def open_linkedin(self):
        site="https://linkedin.com"
        log("open website {}.".format(site))
        self._driver.get(site)
        self.sel("#login-email").send_keys(self._config["linkedin_user"])
        self.sel("#login-password").send_keys(self._config["linkedin_password"])
        self.sel("#login-submit").click()
    def get_connections(self):
        log("get_connections")
        self._driver.get("https://www.linkedin.com/mynetwork/invite-connect/connections/")
        self._connections_fn=pathlib.Path("connections.csv")
        if ( self._connections_fn.exists() ):
            log("connections.csv exists. try to load data from there.")
            df=pd.read_csv(str(self._connections_fn))
            page_connections_number=int(self.selx("//header[@class='mn-connections__header']/h1").text.split(" ")[0])
            if ( ((len(df))==(page_connections_number)) ):
                log("the stored file contains {} connections. same as the website.".format(page_connections_number))
                return df
            else:
                log("the stored file contains {} connections. the website contains {}. load from website".format(len(df), page_connections_number))
        try:
            while (True):
                self.incrementally_scroll_down()
                start=current_milli_time()
                self.wait_xpath_gone("//div[@class='artdeco-spinner']")
                if ( ((((current_milli_time())-(start)))<(120)) ):
                    log("spinner was probably never there. i think we loaded everything.")
                    break
        except selenium.common.exceptions.TimeoutException as e:
            log("timeout waiting for spinner to disappear")
            pass
        res=[]
        for s in self.selxs("//ul/li//a/span[contains (@class, 'card__name')]"):
            res.append({("name"):(s.find_element_by_xpath("../span[contains (@class, 'card__name')]").text),("link"):(s.find_element_by_xpath("..").get_attribute("href")),("occupation"):(s.find_element_by_xpath("../span[contains (@class, 'card__occupation')]").text)})
        return pd.DataFrame(res)
    def get_their_connection_link(self):
        """add the link to the site with other peoples connections to the column self._connections.their_connection_link"""
        log("get_their_connection_link")
        for idx, row in self._connections.iterrows():
            if ( pd.isnull(row.their_connection_link) ):
                log("connection link of {} not yet known. try to get it.".format(row.name))
                self._driver.get(row.link)
                their_connection_link=self.selx("//span[contains(@class,'section__connections')]/..").get_property("href")
                log("connections of {}: {}.".format(row.name, their_connection_link))
                self._connections.at[idx,"their_connection_link"]=their_connection_link
                self._connections.to_csv(str(self._connections_fn))
    def get_her_connections(self, idx):
        url=self._connections["their_connection_link"].iloc[idx]
        log("get_her_connections: get {}".format(url))
        self._driver.get(url)
        while (True):
            self.incrementally_scroll_down()
            log("wait for number of pages")
            start=current_milli_time()
            self.wait_xpath_clickable("//li[@class='artdeco-pagination__indicator artdeco-pagination__indicator--number '][last()]/button/span")
            if ( ((((current_milli_time())-(start)))<(120)) ):
                log("seems to be immediatly there. i think we loaded everything.")
                break
        number_of_pages=int(self.selx("//li[@class='artdeco-pagination__indicator artdeco-pagination__indicator--number '][last()]/button/span").text)
        self._connections.at[idx,"her_connection_number_of_pages"]=number_of_pages
        number_of_connections=int(self.selx("//h3[contains(@class,'search-results__total')]").text.split(" ")[1].replace(",", ""))
        self._connections.at[idx,"her_number_of_connections"]=number_of_connections
        self._connections.to_csv(str(self._connections_fn))
        res=[]
        for p in range(1, ((1)+(number_of_pages))):
            if ( ((1)<(p)) ):
                log("go to page {}/{}".format(p, number_of_pages))
                self._driver.get("{}&page={}".format(self._connections["their_connection_link"].iloc[idx], p))
                while (True):
                    self.incrementally_scroll_down()
                    log("scrolled down. wait for number of pages")
                    start=current_milli_time()
                    self.wait_xpath_clickable("//li[@class='artdeco-pagination__indicator artdeco-pagination__indicator--number '][last()]/button/span")
                    if ( ((((current_milli_time())-(start)))<(120)) ):
                        log("seems to be immediatly there. i think we loaded everything.")
                        break
            elems=self.selxs("//ul[contains(@class,'search-results__list')]/li")
            for e in elems:
                link=None
                name=None
                job=None
                place=None
                try:
                    link=e.find_element_by_xpath(".//a").get_property("href")
                    name=e.find_element_by_xpath(".//span[contains(@class,'actor-name')]").text
                    job=e.find_element_by_xpath(".//p[contains(@class,'subline-level-1')]/span").text
                    place=e.find_element_by_xpath(".//p[contains(@class,'subline-level-2')]/span").text
                    img_src=e.find_element_by_xpath(".//img").get_property("src")
                except Exception as e:
                    warn("e={}".format(str(e)))
                    pass
                log("name={} job={} place={}.".format(name, job, place))
                res.append({("my_name"):(self._connections.name.iloc[idx]),("my_idx"):(idx),("other_link"):(link),("other_name"):(name),("other_job"):(job),("other_place"):(place),("other_img_src"):(img_src),("page"):(p)})
            fn="other_{:04d}_{}".format(idx, str(self._connections_fn))
            log("finished reading page, store in {}.".format(fn))
            pd.DataFrame(res).to_csv(fn)
    def __init__(self, config):
        SeleniumMixin.__init__(self)
        self._config=config
        self.open_linkedin()
        self._connections=self.get_connections()
        for idx, row in self._connections.iterrows():
            if ( not(pd.isnull(row.their_connection_link)) ):
                self.get_her_connections(idx)
l=LinkedIn(config.config)