(eval-when (:compile-toplevel :execute :load-toplevel)
  (ql:quickload "cl-py-generator")
  (ql:quickload "cl-ppcre"))
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
		   ;pathlib
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
		  (setf self._driver (dot selenium.webdriver
					  #+firefox (Firefox)
					  #+chrome (Chrome)
				      )
			self._wait (selenium.webdriver.support.wait.WebDriverWait self._driver 2))
		  (log (string "SeleniumMixin::__init__ finished")))
	 	(def sel (self css)
		  (log (dot (string "sel css={}")
			    (format css)))
		  (return (self._driver.find_element_by_css_selector css)))
		(def selx (self xpath)
		  (log (dot (string "sel xpath={}")
			    (format xpath)))
		  (return (self._driver.find_element_by_xpath xpath)))
		(def wait_css_gone (self css)
		  (log (dot (string "wait gone css={}") (format css)))
		  (self._wait.until (selenium.webdriver.support.expected_conditions.invisibility_of_element_located
                               (tuple selenium.webdriver.common.by.By.CSS_SELECTOR
                                      css))))
		(def wait_css_clickable (self css)
		  (self._wait.until (selenium.webdriver.support.expected_conditions.element_to_be_clickable
                               (tuple selenium.webdriver.common.by.By.CSS_SELECTOR
                                      css))))

		(def wait_xpath_clickable (self xpath)
		  (log (dot (string "wait clickable xpath={}") (format xpath)))
		  (self._wait.until (selenium.webdriver.support.expected_conditions.element_to_be_clickable
			       (tuple selenium.webdriver.common.by.By.XPATH xpath))))
		(def waitsel (self css)
		  (self.wait_css_clickable css)
		  (return (self.sel css)))
		(def waitselx (self xpath)
		  (self.wait_xpath_clickable xpath)
		  (return (self.selx xpath))))
	 
	 

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
		
		(def __init__ (self config)
		  (SeleniumMixin.__init__ self)
		  (setf self._config config)
		  (self.open_linkedin)
		  (self._driver.get (string "https://www.linkedin.com/mynetwork/invite-connect/connections/"))
 		))

	 (setf l (LinkedIn config.config))
	 
	 #+nil
	 (class
	  LinkedIn (SeleniumMixin)
	  
	  (def open_colab (self)
	    (do0
	     (setf site (string "https://colab.research.google.com/notebooks/welcome.ipynb"))
	     (log (dot (string "open website {}.")
		       (format site)))
	       (self._driver.get site)
	       (dot (self.selx  (string "//a[text()='Sign in']"))
		    (click))
	       #+nil
	       (dot (self.sel (string ".gb_gb"))  (click))))
	  (def get_auth_token (self fn &key (newlines False))
	    (do0
	     (setf f (open fn)
		   pw (f.read) )
	     (if (not  newlines)
		 (setf pw (dot pw
			       (replace (string "\\n")
					(string "")))))
	     (f.close))
	    (return pw))
	  (def login (self &key (password_fn (string "/home/martin/stage/cl_ctl_colab/source/p")))
	    (do0
	     (setf pw (self.get_auth_token password_fn))
	     (do0
	      (log (string "enter login name."))

	      ;;(pyperclip.copy (string "martinkielhorn@effectphotonics.nl"))
	      ;(time.sleep 1)
	      #+nil (dot (self.waitsel (string "#identifierId"))
		   (send_keys (+ selenium.webdriver.common.keys.Keys.CONTROL (string "v"))))
	      #+nil
	      (dot (selenium.webdriver.common.action_chains.ActionChains self._driver)
			 (key_down selenium.webdriver.common.keys.Keys.CONTROL)
			 (key_down (string "v"))
			 ;(key_up (string "v"))
			 (key_up selenium.webdriver.common.keys.Keys.CONTROL)
			 (perform)
			 )
	      
	      (dot (self.waitsel (string "#identifierId"))
		   (send_keys (string "")))
	      (dot (self.sel (string "#identifierNext"))
		   (click))))
	    (do0
	     (log (string "enter password."))
	     (dot (self.waitsel (string "input[type='password']"))
		  (send_keys pw))
	     (dot (self.sel (string "#passwordNext"))
		  (click))))

	  (def attach_gpu (self)
	    (do0
	    ;; i used css selector gadget (chromium) and selenium ide in firefox
	    (log (string "enable gpu."))
	    (time.sleep 1)
					;(dot (self.selx (string "(.//*[normalize-space(text()) and normalize-space(.)='Insert'])[1]/following::div[5]")) (click))
	    
					;(dot (self._driver.find_element_by_id (string ":1z")) (click))
	    (dot (self.sel (string "#runtime-menu-button")) (click))
	    (dot (self.waitselx (string "//div[@command='change-runtime-type']")) (click))
	    
	    (dot (self.waitselx (string "//paper-dropdown-menu[@id='accelerators-menu']/paper-menu-button//input"))
		 #+firefox (click)
		 #+chrome
		 (send_keys (string "\\n")))
	    (dot (self.waitselx (string "//paper-item[@value='GPU']"))
		 #+firefox (click)
		 #+chrome (send_keys (string "\\n")))
	    (dot (self.waitsel (string "#ok"))
		 #+firefox (click)
		 #+chrome (send_keys (string "\\n")))
	    ))
	  (def start (self)
	    (do0
	     (log (string "start vm instance."))
	     (dot (self.waitsel (string "#connect .colab-toolbar-button")) (click))))
	  (def stop (self)
	    (do0
	     (log (string "stop vm instance."))
	     (dot (self.sel (string "#runtime-menu-button")) (click))
	     (dot (self.selx (string "//div[@command='manage-sessions']")) (click))
	     
	     ;; click terminate on the vm
	     (dot (self.waitselx (string "//paper-button[text()[contains(.,'Terminate')]]")) (send_keys (string "\\n")))
	     (dot (self.waitselx (string "//paper-button[@id='ok']")) (send_keys (string "\\n")))
	     (dot (self.selx (string "//paper-button[@class='dismiss style-scope colab-sessions-dialog']"))
		  (send_keys (string "\\n")))))
	  #+nil (def set_text (self element text)
	    ;; if (!('value' in elm))
;;  throw new Error('Expected an <input> or <textarea>');

	    (element._parent.execute_script (string3 "var elm = arguments[0], text = arguments[1];
elm.focus();
elm.value = text;
elm.dispatchEvent(new Event('change'));
" element text)))
	  (def run (self code)
	    (log (string "create new code cell."))
		    (dot (self.selx (string "//colab-toolbar-button[@command='add-code']")) (click))
		    (setf entry (self._driver.switch_to_active_element))
		    (log (string "copy code."))
		    
		    
					;(dot entry (send_keys (pyperclip.paste)))
					;(self.set_text entry code)
		    ;(time.sleep 5)
		    (log (string "paste code into cell."))
		    (pyperclip.copy code)

		    (dot (selenium.webdriver.common.action_chains.ActionChains self._driver)
			 (key_down selenium.webdriver.common.keys.Keys.CONTROL)
			 (key_down (string "v"))
			 ;(key_up (string "v"))
			 (key_up selenium.webdriver.common.keys.Keys.CONTROL)
			 (perform)
			 )
		    #+nil
		    (dot entry (send_keys (+ selenium.webdriver.common.keys.Keys.CONTROL (string "v"))))
		    (log (string "execute code cell."))
		    (dot (selenium.webdriver.common.action_chains.ActionChains self._driver)
			 (key_down selenium.webdriver.common.keys.Keys.SHIFT)
			 (key_down selenium.webdriver.common.keys.Keys.ENTER)
			 (key_up selenium.webdriver.common.keys.Keys.ENTER)
			 (key_up selenium.webdriver.common.keys.Keys.SHIFT)
			 (perform)))
	  (def call_shell (self cmd)
	    (setf s (dot cmd (split (string " "))))
	    (setf r (subprocess.call s))
	    (log (dot (string "ran shell command: {} = {}")
		      (format s r)))
	    
	    
	    (return r))
	  (def call_shellt (self cmd)
	    (setf s cmd ;(dot cmd (split (string " ")))
		  )
	    (setf r (subprocess.call s :shell True))
	    (log (dot (string "ran shell command: {} = {}")
		      (format s r)))
	    
	    
	    (return r))
	  (def start_ssh (self)

	    (do0
	     (setf to_here (/ (pathlib.Path (string "/dev/shm/"))
				self._config.server.key)
		   to_google (/ (pathlib.Path (string "/dev/shm/"))
			      self._config.gpu.key))
	     
	   (try
	    (do0 (dot to_google  (unlink))
		 (dot to_here    (unlink)))
	    ("Exception as e"
	     pass))
	   (do0
	    (self.call_shellt (dot (string "/usr/bin/ssh-keygen -t ed25519 -N '' -f {}")
				  (format (str to_google))))
	    (self.call_shellt (dot (string "/usr/bin/ssh-keygen -t ed25519 -N '' -f {}")
				  (format (str to_here))))
	    (self.call_shell (dot (string "scp -P {} {}.pub  {}:/dev/shm/")
				  (format  self._config.server.port (str to_here) self._config.server.hostname))
			     )
	    (self.call_shell (dot (string "ssh -p {} {} sudo chown {}.users /dev/shm/{}.pub")
				  (format self._config.server.port self._config.server.hostname self._config.server.user self._config.server.key ))
			     )
	    (self.call_shell (dot (string "ssh -p {} {} sudo mv /dev/shm/{}.pub /home/{}/.ssh/authorized_keys")
				  (format self._config.server.port self._config.server.hostname self._config.server.key self._config.server.user))
			     )))
	    
	    ;; https://gist.github.com/creotiv/d091515703672ec0bf1a6271336806f0
	    (setf cmd (dot (rstring3 "! apt-get install -qq -o=Dpkg::Use-Pty=0 openssh-server > /dev/null
! mkdir -p /var/run/sshd
! echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
! echo 'LD_LIBRARY_PATH=/usr/lib64-nvidia' >> /root/.bashrc
! echo 'export LD_LIBRARY_PATH' >> /root/.bashrc
! mkdir /root/.ssh
! chmod go-rwx /root/.ssh
! echo '''{}''' >> /root/.ssh/authorized_keys
! echo -e '''{}''' > /root/.ssh/id_ed25519
! chmod og-rwx /root/.ssh/id_ed25519
! echo 'starting sshd'
get_ipython().system_raw('/usr/sbin/sshd -D &')
get_ipython().system_raw('ssh -N -A -t -oServerAliveInterval=15  -oStrictHostKeyChecking=no  -l {} -p {} {} -R 2228:localhost:22 -i /root/.ssh/id_ed25519 &')")
			   ;; ! ssh -N -A -t -oServerAliveInterval=15  -oStrictHostKeyChecking=no  -l {} -p {} {} -R 2228:localhost:22 -i /root/.ssh/id_ed25519
			   (format ;; -N -A -t get_ipython().system_raw('ssh -oServerAliveInterval=15  -oStrictHostKeyChecking=no  -l {} -p {} {} -R 22:localhost:2228 -i /root/.ssh/id_ed25519')
				    (self.get_auth_token (+ (str to_google) (string ".pub")) :newlines False)
				   
				    (dot (self.get_auth_token (str to_here) :newlines True)
					 (replace (string3 "
")
						  (string "\\\\n")))
				    self._config.server.user
				    self._config.server.port
				    self._config.server.hostname)))
	    (self.run cmd))
	  (def __init__ (self config)
	    (SeleniumMixin.__init__ self)
	    (setf self._config config)
	    (self.open_colab)
 	    (self.login)
	    (self.attach_gpu)
	    (self.start)
	    
	    ))
	 #+nil
	 (do0
	  (setf colab (Colaboratory config.config))
	  (do0
	   (setf self colab)
	   )
	  
	  (colab.start_ssh)))))
  (write-source "/home/martin/stage/cl_ctl_linkedin/source/run_00_start" code)
  (write-source "/home/martin/stage/cl_ctl_linkedin/source/config.changeme" config-code)
  (write-source "/home/martin/stage/cl_ctl_linkedin/source/s"
		`(do0
		  
		  (def run (linkedin)
		    (setf self linkedin)
		    (self._driver.get (string "https://www.linkedin.com/mynetwork/invite-connect/connections/")))
		)))

;; # click on one of my connections (iterate through those, get name and link)
;; self.sel('li.list-style-none').click()
;; # listing "People also viewed" (iterate through those, get name, position, affiliation)
;; self.sel('li.pv-browsemap-section__member-container')
;; # see their connections
;; self.sel('.pv-top-card-v2-section__connections')
