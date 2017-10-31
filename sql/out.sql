## Needed if you want to enable compression
#SET GLOBAL innodb_file_per_table=1;
#SET GLOBAL innodb_file_format=Barracuda;


SET NAMES ascii COLLATE ascii_bin;
SET default_storage_engine=INNODB;

CREATE SCHEMA IF NOT EXISTS `btc_blockchain` CHARACTER SET ascii COLLATE ascii_bin;
USE `btc_blockchain`;


DROP TABLE IF EXISTS `tx_out`;
CREATE TABLE `tx_out` (
  `id`              int(4) unsigned AUTO_INCREMENT      NOT NULL,
  `txid`            binary(32)                  		NOT NULL,
  `indexOut`        int(10) unsigned            		NOT NULL,
  `value`           bigint(8) unsigned            		NOT NULL,
  `scriptPubKey`    blob                                NOT NULL,
  `address`     	varchar(36) 					DEFAULT NULL,
  `unspent`        	bit DEFAULT TRUE                    NOT NULL,

  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
#  ROW_FORMAT=DYNAMIC;


SET @@session.unique_checks = 0;
SET @@session.foreign_key_checks = 0;
SET @@session.sync_binlog = 0;

# Speed up bulk load
SET autocommit = 0;
SET sql_safe_updates = 0;
SET sql_log_bin=0;


TRUNCATE tx_out;
## Load tx_out into table
LOAD DATA INFILE '/media/tmp/dump/tx_out-0-393489.csv'
INTO TABLE tx_out
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
(@txid, indexOut, value, @scriptPubKey, address)
SET txid = unhex(@txid),
	scriptPubKey = unhex(@scriptPubKey);
COMMIT;


SET @@session.unique_checks = 1;
SET @@session.foreign_key_checks = 1;

# Add keys
ALTER TABLE `blocks` ADD UNIQUE KEY (`hash`);
ALTER TABLE `transactions` ADD KEY (`txid`);
ALTER TABLE `tx_in` ADD KEY (`hashPrevOut`, `indexPrevOut`);
ALTER TABLE `tx_out` ADD KEY (`txid`, `indexOut`),
					 ADD KEY (`address`);
#ALTER TABLE `transactions` ADD FOREIGN KEY (`hashBlock`) REFERENCES blocks(`hash`);
#ALTER TABLE `tx_out` ADD FOREIGN KEY (`txid`) REFERENCES transactions(`txid`);
#ALTER TABLE `tx_id` ADD FOREIGN KEY (`txid`) REFERENCES transactions(`txid`);
COMMIT;

# Flag spent tx outputs
UPDATE `tx_out` o, `tx_in` i
	SET o.unspent = FALSE
WHERE o.txid = i.hashPrevOut
  AND o.indexOut = i.indexPrevOut;
COMMIT;


SET autocommit = 1;
SET sql_log_bin=1;
SET @@session.sync_binlog=1;
SET sql_safe_updates = 1;
