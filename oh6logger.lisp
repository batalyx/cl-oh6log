
;;; log-db -----------------------------------------------------

(defvar *call-max-length* 20)
(defvar *rst-length*       5)
(defvar *mode-length*      5)
(defvar *info-length*      5)

(defstruct (log-entry
	     (:constructor make-log-entry)
	     (:constructor make-log-entry-boa
			   (start-time end-time
			    remote-station rst-sent rst-received
			    frequency mode
			    info qsl-sent qsl-received)))
  start-time
  end-time
  remote-station
  rst-sent
  rst-received
  frequency
  mode
  info
  qsl-sent
  qsl-received)


(defvar *DB-USER-VERSION* 1)
(defvar *DB-DIR-NAME*     ".oh6logger/")
(defvar *DB-FILE*         "log.db")

(defvar *CREATE-DB* "
 BEGIN;
 CREATE TABLE log_entry
  (
  start_time INTEGER PRIMARY KEY, 
  end_time INTEGER NOT NULL, 
  remote_station TEXT NOT NULL, 
  RST_sent TEXT, 
  RST_received TEXT, 
  frequency INTEGER NOT NULL, 
  mode TEXT NOT NULL, 
  info TEXT NOT NULL DEFAULT '', 
  QSL_sent INTEGER NOT NULL, 
  QSL_received INTEGER NOT NULL 
  ); 

 CREATE TABLE dxcc 
  ( 
  prefix TEXT PRIMARY KEY, 
  entity TEXT NOT NULL 
  ); 

PRAGMA user_version = 1; 

COMMIT;
")

(defvar *db* nil "Global database reference.")

(defun db-user-version ()
  (sqlite:execute-single *db* "PRAGMA user_version;"))

(defun db-open ()
  (let ((user-version 0)
	(db-path (merge-pathnames *DB-DIR-NAME* (user-homedir-pathname))))
    ;; add db_dir_name to getenv(HOME)

    ;; check if working directory exists and create it if not
    (setq db-path (ensure-directories-exist db-path :verbose t))

    ;; add file name to path
    (setq db-path (merge-pathnames *DB-FILE* db-path))

    ;; open database
    (setq *db* (sqlite:connect db-path)) ; TODO check restart case (error)

    ;; get db_user_version
    (setq user-version (db-user-version))

    (format t "user-version ~d~%" user-version)

    (if (= 0 user-version)
	;; if user version 0, create db
	(sqlite:execute-to-list *db* *CREATE-DB*) ; ei pelitä "multiple statements in sql"
	;; else, if user versio != DB_USER_VERSION, quit
	(unless (= *DB-USER-VERSION* user-version)
	  (sqlite:disconnect *db*)))
    *db*))

(defun db-close ()
  (sqlite:disconnect *db*))

(defvar *sql-add-log-entry*
  "INSERT INTO log_entry VALUES
   (?,?,?,?,?,?,?,?,?,?);")

(defun db-add-qso (entry)
  (sqlite:execute-non-query *db* *sql-add-log-entry*
			    (log-entry-start-time entry)
			    (log-entry-end-time entry)
			    (log-entry-remote-station entry)
			    (log-entry-rst-sent entry)
			    (log-entry-rst-received entry)
			    (log-entry-frequency entry)
			    (log-entry-mode entry)
			    (log-entry-info entry)
			    (log-entry-qsl-sent entry)
			    (log-entry-qsl-received entry)))


(defvar *sql-get-log-entries-by-time*
  "SELECT * FROM log_entry WHERE
   start_time >= :sts AND start_time <= :ste
   limit :lim offset :off;")

(defun db-get-log-entries-by-time (start end limit offset)
  (iterate:iter
    (iterate:for
     (start-time end-time remote-station
      rst-sent rst-received frequency
      mode info qsl-sent qsl-received)
     in-sqlite-query/named *sql-get-log-entries-by-time*
     on-database *db*
     with-parameters (":sts" start ":ste" end ":lim" limit ":off" offset))
    (iterate:collect
	(make-log-entry-boa
	   start-time end-time remote-station rst-sent rst-received
	   frequency mode info qsl-sent qsl-received))))

;;; timehandling ------------------------------------------------

;; from lisptips.com
(defvar *unix-epoch-difference*
  (encode-universal-time 0 0 0 1 1 1970 0))

(defun universal-to-unix-time (universal-time)
  (- universal-time *unix-epoch-difference*))

(defun unix-to-universal-time (unix-time)
  (+ unix-time *unix-epoch-difference*))

(defun get-unix-time ()
  (universal-to-unix-time (get-universal-time)))
;;; end of stuff from lisptips.com


;;; oh6logger ---------------------------------------------------

(defun usage (name))

(defun log-help ())
(defun log-quit ())
(defun log-print ())
(defun log-add ())

(defun parse (s))
(defun find-command ())

(defun main ()
  (let ((result 0)
	(old-tz (or
		 #+SBCL (sb-posix::getenv "TZ")
		 #-SBCL nil))
	(input nil))
    ;; read command line parameters
    ;; open db
    ;; show version
    ;; loop forever
    ;; use gmt always
    ;; (sb-posix::putenv "TZ=EET")
    ;; (sb-posix::unsetenv "TZ")
    #+SBCL
    (sb-posix::putenv "TZ=GMT")
    ;; read input
    ;; trim off extra spaces in input
    ;; parse input
    ;; run action if not null
    ;; leave loop if result of action not 0
    #+SBCL
    (if old-tz
	(sb-posix::setenv "TZ" old-tz 1)
	(sb-posix::unsetenv "TZ"))))
