(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-py-generator")
  ;(ql:quickload "cl-ppcre")
  )
(progn
  (setf *features* (set-difference *features* '(:firefox :chrome)))
  (setf *features* (union *features* '(:firefox ; :chrome
				       ))))

(in-package :cl-py-generator)

;; /dev/shm
;; p              .. linkedin account
;; host_password  .. local users password
;; host           .. internet ip or hostname


(let ((config-code
      `(do0
	(setf config (dict ((string "linkedin_user") (string "bla"))
			   ((string "linkedin_password") (string "foo"))
			   ))))
      (code
       `(do0
	 (imports (sys
		   time
		   config
		   pathlib
		   selenium
		   selenium.webdriver
		   selenium.webdriver.common
		   selenium.webdriver.common.keys
		   selenium.webdriver.common.action_chains
		   selenium.webdriver.support
		   selenium.webdriver.support.ui
		   selenium.webdriver.support.wait
		   selenium.webdriver.support.expected_conditions
					;selenium.webdriver.firefox
		   ;pyperclip
					;subprocess
		   (pd pandas)
		   ))


	 (do0
	  (def current_milli_time ()
            (return (int (round (* 1000 (time.time))))))
	  

          (do0
           "global g_last_timestamp"
           (setf g_last_timestamp (current_milli_time))
           (def milli_since_last ()
             "global g_last_timestamp"
             (setf current_time (current_milli_time)
                   res (- current_time g_last_timestamp)
                   g_last_timestamp current_time)
             (return res)))

	  (class bcolors ()
                 (setf OKGREEN (string "\\033[92m")
                       WARNING (string "\\033[93m")
                       FAIL (string "\\033[91m")
                       ENDC (string "\\033[0m")))
	  
          (def log (msg)
            (print (+ bcolors.OKGREEN
                      (dot (string "{:8d} LOG ")
                           (format (milli_since_last)))
                      msg
                      bcolors.ENDC))
            (sys.stdout.flush))
          (def fail (msg)
            (print (+ bcolors.FAIL
                      (dot (string "{:8d} FAIL ")
                           (format (milli_since_last)))
                      msg
                      bcolors.ENDC))
            (sys.stdout.flush))
          



          (def warn (msg)
            (print (+ bcolors.WARNING
                      (dot (string "{:8d} WARNING ")
                           (format (milli_since_last)))
                      msg
                      bcolors.ENDC))
            (sys.stdout.flush)))
	 
	 (class SeleniumMixin (object)
		(def __init__ (self)
		  (log (string "SeleniumMixin::__init__"))
		  #+firefox
		  (do0
		   (setf profile (selenium.webdriver.FirefoxProfile))
		   (profile.set_preference (string "permissions.default.image") 2))
		  (setf self._driver (dot selenium.webdriver
					  #+firefox (Firefox ;:firefox_profile profile
						     )
					  #+chrome (Chrome)
				      )
			self._wait (selenium.webdriver.support.wait.WebDriverWait self._driver 5))
		  (log (string "SeleniumMixin::__init__ finished")))
	 	(def sel (self css)
		  (log (dot (string "sel css={}")
			    (format css)))
		  (return (self._driver.find_element_by_css_selector css)))
		(def sels (self css)
		  (log (dot (string "sels css={}")
			    (format css)))
		  (return (self._driver.find_elements_by_css_selector css)))
		(def selx (self xpath)
		  (log (dot (string "sel xpath={}")
			    (format xpath)))
		  (return (self._driver.find_element_by_xpath xpath)))
		(def selxs (self xpath)
		  (log (dot (string "sel xpath={}")
			    (format xpath)))
		  (return (self._driver.find_elements_by_xpath xpath)))
		(def wait_css_gone (self css)
		  (log (dot (string "wait gone css={}") (format css)))
		  (self._wait.until (selenium.webdriver.support.expected_conditions.invisibility_of_element_located
                               (tuple selenium.webdriver.common.by.By.CSS_SELECTOR
                                      css))))
		(def wait_css_clickable (self css)
		  (self._wait.until (selenium.webdriver.support.expected_conditions.element_to_be_clickable
                               (tuple selenium.webdriver.common.by.By.CSS_SELECTOR
                                      css))))
		(def wait_xpath_gone (self xpath)
		  (log (dot (string "wait gone xpath={}") (format xpath)))
		  (self._wait.until (selenium.webdriver.support.expected_conditions.invisibility_of_element_located
                               (tuple selenium.webdriver.common.by.By.XPATH xpath))))
		(def wait_xpath_clickable (self xpath)
		  (log (dot (string "wait clickable xpath={}") (format xpath)))
		  (self._wait.until (selenium.webdriver.support.expected_conditions.element_to_be_clickable
			       (tuple selenium.webdriver.common.by.By.XPATH xpath))))
		(def waitsel (self css)
		  (self.wait_css_clickable css)
		  (return (self.sel css)))
		(def waitselx (self xpath)
		  (self.wait_xpath_clickable xpath)
		  (return (self.selx xpath)))
		(def current_scroll_height (self)
		  (setf h (self._driver.execute_script (string "return document.body.scrollHeight")))
		  (log (dot (string "scroll_height={}")
			    (format h)))
		  (return h))
		(def current_client_height (self)
		  (setf h (self._driver.execute_script (string "return document.body.clientHeight")))
		  (log (dot (string "client_height={}")
			    (format h)))
		  (return h))
		(def incrementally_scroll_down (self &key (pause_time .2))
		  (setf last_height (self.current_scroll_height))
		  (while True
		    (self.current_client_height)
		    (self._driver.execute_script (dot (string "window.scrollTo(0, {}+document.body.clientHeight);")
						      (format last_height)))
		    (time.sleep pause_time)
		    (setf new_height (self.current_scroll_height))
		    (if (== new_height last_height)
			(do0
			 (log (string "reached end of page."))
			 break))
		    (setf last_height new_height))))
	 
	 (class LinkedIn (SeleniumMixin)
		(def open_linkedin (self)
		  (do0
		   (setf site (string "https://linkedin.com"))
		   (log (dot (string "open website {}.")
			     (format site)))
		   (self._driver.get site)
		   (dot (self.sel (string "#login-email")) (send_keys (aref self._config (string "linkedin_user"))))
 		   (dot (self.sel (string "#login-password")) (send_keys (aref self._config (string "linkedin_password"))))
		   (dot (self.sel  (string "#login-submit")) (click))))

		(def get_connections (self)
		  (log (string "get_connections"))
		  (self._driver.get (string "https://www.linkedin.com/mynetwork/invite-connect/connections/"))
		  (setf self._connections_fn (pathlib.Path (string "connections.csv")))
		  (if (dot self._connections_fn (exists))
		      (do0
		       (log (string "connections.csv exists. try to load data from there."))
		       (setf df (pd.read_csv (str self._connections_fn))
			     page_connections_number (int (dot (self.selx (string "//header[@class='mn-connections__header']/h1"))
							       text
							       (aref (split  (string " ")) 0)
							       )))
		       (if (== (len df) page_connections_number)
			   (do0
			    (log (dot (string "the stored file contains {} connections. same as the website.")
				      (format page_connections_number)))
			    (return df))
			   (do0
			    (log (dot (string "the stored file contains {} connections. the website contains {}. load from website")
				      (format (len df) page_connections_number)))))))

		  ;;int(l.selx("//header[@class='mn-connections__header']/h1").text.split(' ')[0])
		  
		  (try
		   (while True
		     (self.incrementally_scroll_down)
		     ;(self._driver.execute_script (string "window.scrollTo(0, document.body.scrollHeight)"))
		     ;(log (string "scrolled down."))
		     (setf start (current_milli_time))
		     (self.wait_xpath_gone (string "//div[@class='artdeco-spinner']"))
		     (if (< (- (current_milli_time) start) 120)
			 (do0
			  (log (string "spinner was probably never there. i think we loaded everything."))
			  break)))
		   ("selenium.common.exceptions.TimeoutException as e"
		    (log (string "timeout waiting for spinner to disappear"))
		    pass))
		  (setf res (list))
		    (for (s (self.selxs (string "//ul/li//a/span[contains (@class, 'card__name')]")))
			 (res.append
			  (dict ((string "name")
				 (dot s
				      (find_element_by_xpath (string "../span[contains (@class, 'card__name')]"))
				      text))
				((string "link")
				 (dot s
				      (find_element_by_xpath (string ".."))
				      (get_attribute (string "href"))))
				((string "occupation")
				 (dot s
				      (find_element_by_xpath (string "../span[contains (@class, 'card__occupation')]"))
				      text)))))
		    (return (pd.DataFrame res)))
		(def get_their_connection_link (self)
		  (string3 "add the link to the site with other peoples connections to the column self._connections.their_connection_link")
		  (log (string "get_their_connection_link"))
		  (for ((ntuple idx row) (self._connections.iterrows))
		       (if (pd.isnull row.their_connection_link)
			   (do0
			    (log (dot (string "connection link of {} not yet known. try to get it.")
				      (format row.name)))
			    (self._driver.get row.link)
			    (setf their_connection_link (dot
							 (self.selx (string "//span[contains(@class,'section__connections')]/.."))
							 (get_property (string "href"))))
			    (log (dot (string "connections of {}: {}.")
				      (format row.name their_connection_link)))
			    (setf (aref self._connections.at idx (string "their_connection_link")) their_connection_link)
			    (self._connections.to_csv (str self._connections_fn))))) )
		(def get_her_connections (self idx)
		  (setf url (dot (aref self._connections (string "their_connection_link"))
					 (aref iloc idx)))
		  (log (dot (string "get_her_connections: get {}")
			    (format url)))
		  (self._driver.get url)
		  (while True
		    (self.incrementally_scroll_down)
		     ;(self._driver.execute_script (string "window.scrollTo(0, document.body.scrollHeight)"))
		     (log  (string "wait for number of pages"))
		     (setf start (current_milli_time))
		     (self.wait_xpath_clickable (string "//li[@class='artdeco-pagination__indicator artdeco-pagination__indicator--number '][last()]/button/span"))
		     (if (< (- (current_milli_time) start) 120)
			 (do0
			  (log (string "seems to be immediatly there. i think we loaded everything."))
			  break)))
		  (setf number_of_pages (int (dot (self.selx (string "//li[@class='artdeco-pagination__indicator artdeco-pagination__indicator--number '][last()]/button/span")) text))
			(aref self._connections.at idx (string "her_connection_number_of_pages")) number_of_pages
			number_of_connections (int (dot (self.selx (string "//h3[contains(@class,'search-results__total')]"))
							text
							(aref (split (string " ")) 1)
							(replace (string ",") (string ""))))
			(aref self._connections.at idx (string "her_number_of_connections")) number_of_connections)
		  
		  (self._connections.to_csv (str self._connections_fn))
		  ;; l.selxs("//ul[contains(@class,'search-results__list')]/li")[0].find_element_by_xpath("//a").get_property('href')
		  ;; l.selxs("//ul[contains(@class,'search-results__list')]/li")[0].find_element_by_xpath("//span[contains(@class,'actor-name')]").text
		  (setf res (list))
		  (for (p ;(range 1 (+ 1 number_of_pages))
			  (list 1))
		       (if (< 1 p)
			   (do0
			    (log (dot (string "go to page {}/{}")
				      (format p number_of_pages)))
			    (self._driver.get (dot (string "{}&page={}")
						   (format (dot (aref self._connections (string "their_connection_link"))
								(aref iloc idx))
							   p)))
			    (while True
			      (self.incrementally_scroll_down)
			      ;(self._driver.execute_script (string "window.scrollTo(0, document.body.scrollHeight)"))
			      (log  (string "scrolled down. wait for number of pages"))
			      (setf start (current_milli_time))
			      (self.wait_xpath_clickable (string "//li[@class='artdeco-pagination__indicator artdeco-pagination__indicator--number '][last()]/button/span"))
			      (if (< (- (current_milli_time) start) 120)
				  (do0
				   (log (string "seems to be immediatly there. i think we loaded everything."))
				   break)))))
		       ;; in javascript console
		       ;; b = $x(("//ul[contains(@class,'search-results__list')]/li"))
		       ;; document.evaluate( 'count(//p)', b[9], null, XPathResult.ANY_TYPE, null );
		       (setf elems (self.selxs (string "//ul[contains(@class,'search-results__list')]/li")))
		       (for (e elems) ;; FIXME: i don't think this is iterating all the list elements
			    (setf link None
				  name None
				  job None
				  place None)
			    (try
			     (setf link (dot e (find_element_by_xpath (string ".//a"))
					     (get_property (string "href")))
				   name (dot e (find_element_by_xpath (string ".//span[contains(@class,'actor-name')]"))
					     text)
				   job (dot e (find_element_by_xpath (string ".//p[contains(@class,'subline-level-1')]/span"))
					    text)
				   place (dot e (find_element_by_xpath (string ".//p[contains(@class,'subline-level-2')]/span"))
					      text)
				   img_src (dot e (find_element_by_xpath (string ".//img"))
					      (get_property (string "src"))))
			     ("Exception as e"
			      (warn (dot (string "e={}")
					 (format (str e))))
			      pass))
			    (log (dot (string "name={} job={} place={}.")
				      (format name job place)))
			    (res.append (dict ((string "my_name") (aref self._connections.name.iloc idx))
					      ((string "my_idx") idx)
					      ((string "other_link") link)
					      ((string "other_name") name)
					      ((string "other_job") job)
					      ((string "other_place") place)
					      ((string "other_img_src") img_src)
					      ((string "page") p))))
		       (do0
			(setf fn (dot (string "other_{:04d}_{}")
					  (format
					   idx
					   (str self._connections_fn))))
			(log (dot (string "finished reading page, store in {}.")
				  (format fn)))
			(dot (pd.DataFrame res)
			     (to_csv fn)))))
		(def __init__ (self config)
		  (SeleniumMixin.__init__ self)
		  (setf self._config config)
		  (self.open_linkedin)
		  (setf self._connections (self.get_connections))
		  #+nil(self.get_their_connection_link)
		  (try
		   (self.get_her_connections 0)
		   ("Exception as e"
		    pass))
		  #+nil (for ((ntuple idx row) (self._connections.iterrows))
		       (if (not (pd.isnull row.their_connection_link))
			   (do0
			    (self.get_her_connections idx))))
 		))

	 (setf l (LinkedIn config.config)))))
  (write-source "/home/martin/stage/cl_ctl_linkedin/source/run_00_start" code)
  (write-source "/home/martin/stage/cl_ctl_linkedin/source/config.changeme" config-code)
  (write-source "/home/martin/stage/cl_ctl_linkedin/source/s"
		`(do0
		  
		  (def run (linkedin)
		    (setf self linkedin)
					;(self._driver.get (string "https://www.linkedin.com/mynetwork/invite-connect/connections/"))
		    (setf res (list))
		    (for (s (self.sels (string "li.list-style-none")))
			 (res.append
			  (dict ((string "name")
				 (dot s
				      (find_element_by_xpath (string "//span[contains (@class, 'card__name')]"))
				      (text)))
				((string "occupation")
				 (dot s
				      (find_element_by_xpath (string "//span[contains (@class, 'card__occupation')]"))
				      (text))))))
		    (return res)))))

;; # click on one of my connections (iterate through those, get name and link)
;; self.sel('li.list-style-none').click()
;; # listing "People also viewed" (iterate through those, get name, position, affiliation)
;; self.sel('li.pv-browsemap-section__member-container')
;; # see their connections
;; self.sel('.pv-top-card-v2-section__connections')
