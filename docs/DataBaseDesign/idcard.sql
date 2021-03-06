DROP TABLE IF EXISTS BC_IDCARD_CHECK;
DROP TABLE IF EXISTS BC_IDCARD;
DROP TABLE IF EXISTS BC_IDCARD_PIC;
DROP sequence IF EXISTS IDCARD_SEQUENCE;

-- 创建刷卡记录用的序列，开始于1000
CREATE sequence IDCARD_SEQUENCE
    minvalue 1
    start with 1000
    increment by 1
    cache 20;

CREATE TABLE BC_IDCARD(
	ID INT NOT NULL,
	TYPE_ int NOT NULL default 0,
	CODE VARCHAR(20) NOT NULL,
	NAME VARCHAR(255) NOT NULL,
	SEX VARCHAR(10) NOT NULL,
	FOLK VARCHAR(10) NOT NULL,
	BIRTHDATE date NOT NULL,
	ISSUE VARCHAR(255) NOT NULL,
	START_DATE date NOT NULL,
	END_DATE date NOT NULL,
	ADDRESS VARCHAR(500) NOT NULL,
	NEW_ADDRESS VARCHAR(500),
	FILE_DATE TIMESTAMP NOT NULL,
	AUTHOR_ID int NOT NULL,
	MODIFIED_DATE TIMESTAMP,
	MODIFIER_ID int,
	ISNEW int NOT NULL default 0,
	CONSTRAINT BCPK_IDCARD PRIMARY KEY (ID),
	CONSTRAINT BCUK_IDCARD_NUM UNIQUE (TYPE_,CODE)
);
COMMENT ON TABLE BC_IDCARD IS '身份证';
COMMENT ON COLUMN BC_IDCARD.ID IS 'ID';
COMMENT ON COLUMN BC_IDCARD.TYPE_ IS '用途:0-司机招聘,1-系统用户';
COMMENT ON COLUMN BC_IDCARD.CODE IS '身份证号';
COMMENT ON COLUMN BC_IDCARD.NAME IS '姓名';
COMMENT ON COLUMN BC_IDCARD.SEX IS '性别';
COMMENT ON COLUMN BC_IDCARD.FOLK IS '民族 : (不带路径的部分)';
COMMENT ON COLUMN BC_IDCARD.BIRTHDATE IS '出生日期';
COMMENT ON COLUMN BC_IDCARD.ISSUE IS '签发机关';
COMMENT ON COLUMN BC_IDCARD.START_DATE IS '有效期-开始';
COMMENT ON COLUMN BC_IDCARD.END_DATE IS '有效期-结束';
COMMENT ON COLUMN BC_IDCARD.ADDRESS IS '住址';
COMMENT ON COLUMN BC_IDCARD.NEW_ADDRESS IS '最新住址';
COMMENT ON COLUMN BC_IDCARD.ISNEW IS '是否为最新记录:0-最新,1-历史';
COMMENT ON COLUMN BC_IDCARD.FILE_DATE IS '创建时间';
COMMENT ON COLUMN BC_IDCARD.AUTHOR_ID IS '创建人:对应Actor的ID';
COMMENT ON COLUMN BC_IDCARD.MODIFIED_DATE IS '最后更新时间';
COMMENT ON COLUMN BC_IDCARD.MODIFIER_ID IS '最后更新人:对应Actor的ID';
ALTER TABLE BC_IDCARD ADD CONSTRAINT BCFK_IDCARD_AUTHOR FOREIGN KEY (AUTHOR_ID)
	REFERENCES BC_IDENTITY_ACTOR (ID) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE BC_IDCARD ADD CONSTRAINT BCFK_IDCARD_MODIFIER FOREIGN KEY (MODIFIER_ID)
	REFERENCES BC_IDENTITY_ACTOR (ID) ON UPDATE RESTRICT ON DELETE RESTRICT;
CREATE INDEX BCIDX_IDCARD_CODE ON BC_IDCARD (TYPE_, CODE, ISNEW);

-- 身份证图像
CREATE TABLE BC_IDCARD_PIC(
	ID INT NOT NULL,
	TYPE_ VARCHAR(5) NOT NULL,
	PID INT NOT NULL,
	FILE_DATE TIMESTAMP NOT NULL,
	DATA_ BYTEA,
	CONSTRAINT BCPK_IDCARD_PIC PRIMARY KEY (ID)
);
COMMENT ON TABLE BC_IDCARD_PIC IS '身份证图像';
COMMENT ON COLUMN BC_IDCARD_PIC.TYPE_ IS '图片类型：如png、bmp';
COMMENT ON COLUMN BC_IDCARD_PIC.PID IS '所属身份证的ID';
COMMENT ON COLUMN BC_IDCARD_PIC.FILE_DATE IS '创建日期';
COMMENT ON COLUMN BC_IDCARD_PIC.DATA_ IS '图像的二进制数据';
ALTER TABLE BC_IDCARD_PIC ADD CONSTRAINT BCFK_IDCARD_PIC FOREIGN KEY (PID)
	REFERENCES BC_IDCARD (ID) ON UPDATE RESTRICT ON DELETE RESTRICT;

CREATE TABLE BC_IDCARD_CHECK(
	ID INT NOT NULL,
	PID INT NOT NULL,
	FILE_DATE TIMESTAMP NOT NULL,
	AUTHOR_ID int NOT NULL,
	CONSTRAINT BCPK_IDCARD_CHECK PRIMARY KEY (ID)
);
COMMENT ON TABLE BC_IDCARD_CHECK IS '刷卡记录';
COMMENT ON COLUMN BC_IDCARD_CHECK.ID IS 'ID';
COMMENT ON COLUMN BC_IDCARD_CHECK.PID IS '身份证';
COMMENT ON COLUMN BC_IDCARD_CHECK.FILE_DATE IS '刷卡时间';
COMMENT ON COLUMN BC_IDCARD.AUTHOR_ID IS '创建人:对应Actor的ID';
ALTER TABLE BC_IDCARD_CHECK ADD CONSTRAINT BC_IDCARD_CHECK_PID FOREIGN KEY (PID)
	REFERENCES BC_IDCARD (ID) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE BC_IDCARD_CHECK ADD CONSTRAINT BCFK_IDCARD_CHECK_AUTHOR FOREIGN KEY (AUTHOR_ID)
	REFERENCES BC_IDENTITY_ACTOR (ID) ON UPDATE RESTRICT ON DELETE RESTRICT;

-- 身份证读卡器使用岗
insert into BC_IDENTITY_ACTOR (ID,UID_,STATUS_,INNER_,TYPE_,CODE, NAME, ORDER_,PCODE,PNAME) 
	select NEXTVAL('CORE_SEQUENCE'),'IDCARD_USERS', 0, true, 3, 'IDCARD_USERS','身份证读卡器使用岗', '0000',null,null
	from bc_dual
	where not exists (select 0 from BC_IDENTITY_ACTOR where CODE='IDCARD_USERS'); 
insert into BC_IDENTITY_ACTOR_RELATION (TYPE_,MASTER_ID,FOLLOWER_ID) 
    select 0,am.id,af.id from BC_IDENTITY_ACTOR am,BC_IDENTITY_ACTOR af 
	where am.code='baochengzongbu' and af.code='IDCARD_USERS'
	and not exists (select 0 from BC_IDENTITY_ACTOR_RELATION ar where ar.TYPE_=0 and ar.MASTER_ID=am.id and ar.FOLLOWER_ID=af.id); 
insert into BC_IDENTITY_ACTOR_RELATION (TYPE_,MASTER_ID,FOLLOWER_ID) 
    select 0,am.id,af.id from BC_IDENTITY_ACTOR am,BC_IDENTITY_ACTOR af 
	where am.code='IDCARD_USERS' and af.code in ('admin','ghy','xu','hrj','lubaojin','zxr')
	and not exists (select 0 from BC_IDENTITY_ACTOR_RELATION ar where ar.TYPE_=0 and ar.MASTER_ID=am.id and ar.FOLLOWER_ID=af.id); 

-- 插入同步司机照片的定时任务
INSERT INTO bc_sd_job(id, status_, name, groupn, cron, bean, method, order_, memo_, ignore_error)
    select NEXTVAL('hibernate_sequence'), 1,'同步身份证刷卡器的照片到司机招聘库','bc'
	,'0 1 0 * * ? *','tempDriverService','doSyncPortrait','0002'
    ,'', false from bc_dual
    where not exists (select 0 from bc_sd_job where bean='tempDriverService' and method='doSyncPortrait');

-- 创建触发器
CREATE or Replace FUNCTION antoInsertTempDriver() RETURNS trigger AS $$  
DECLARE
	guy RECORD;
	driver_id int := 0;	
BEGIN
	FOR guy IN select * from bc_idcard where id=NEW.pid LOOP
		-- 获取已经存在的司机的id
		select id into driver_id from bs_temp_driver where cert_identity=guy.code limit 1;

		If (driver_id > 0) THEN  -- 司机已存在：更新身份证信息、最后修改信息
			update bs_temp_driver set name=guy.name
				,sex=to_number(guy.sex,'FM999')
				,nation=guy.FOLK
				,birthdate=guy.BIRTHDATE
				,address=guy.ADDRESS
				,issue=guy.ISSUE
				,valid_start_date=guy.START_DATE
				,valid_end_date=guy.END_DATE
				,register_date=guy.FILE_DATE
				,modifier_id=(select id from bc_identity_actor_history where current=true and actor_id=guy.author_id)
				,modified_date=NEW.FILE_DATE
				,origin=getplaceoriginbycertidentity(guy.code)
				where id=driver_id;
			return null; 
		Else   -- 司机不存在：插入新的信息
			INSERT INTO bs_temp_driver(id,uid_,status_,name
				,sex,nation,birthdate,address
				,cert_identity,issue,valid_start_date,valid_end_date,register_date
				,file_date,author_id,modified_date,modifier_id,origin,region_)
				VALUES (NEXTVAL('hibernate_sequence'),'tempDriver.auid.'||NEXTVAL('hibernate_sequence'),0,guy.name
				,to_number(guy.sex,'FM999'),guy.FOLK,guy.BIRTHDATE,guy.ADDRESS
				,guy.code,guy.ISSUE,guy.START_DATE,guy.END_DATE,guy.FILE_DATE
				,guy.FILE_DATE,(select id from bc_identity_actor_history where current=true and actor_id=guy.author_id)
				,guy.FILE_DATE,(select id from bc_identity_actor_history where current=true and actor_id=guy.author_id)
				,getplaceoriginbycertidentity(guy.code)
				,CASE WHEN guy.address like '%广州%' THEN 1 
					WHEN guy.address like '%广东%' THEN 2 
					WHEN guy.CODE like '44%' THEN 2 
					ELSE 3 END);
			return null;  
		END IF;
	END LOOP;
	return null;
END;
$$ LANGUAGE plpgsql;  
DROP TRIGGER IF EXISTS trigger_antoInsertTempDriver on BC_IDCARD;
DROP TRIGGER IF EXISTS trigger_antoInsertTempDriver on BC_IDCARD_CHECK;
CREATE TRIGGER trigger_antoInsertTempDriver AFTER INSERT ON BC_IDCARD_CHECK  
    FOR EACH ROW EXECUTE PROCEDURE antoInsertTempDriver();

-- test
INSERT INTO bc_idcard(id, code, name, sex, folk, birthdate, issue, start_date, end_date, address, file_date, author_id)
    VALUES (1, 'ID01','dragon', '1', '汉族', '1976-02-01', '广州市公安局', '2006-02-01', '2026-02-01', '广州市XXX001',now(),9);
INSERT INTO bc_idcard_check(id, pid, file_date, author_id)
    VALUES (NEXTVAL('hibernate_sequence'), 1, now(),9);

-- 刷卡器的登录sql
select * from bc_identity_actor u 
	inner join bc_identity_auth a on a.id=u.id
	inner join bc_identity_actor_relation ur on ur.follower_id = u.id and ur.type_=0
	inner join bc_identity_actor g on g.id = ur.master_id and g.type_=3
	where u.type_=4 and u.code='dragon' and a.password = '21218cca77804d2ba1922c33e0151105'
	and g.code='IDCARD_USERS';

-- 清空删除测试数据
delete from bc_idcard_check;
delete from bc_idcard_pic;
delete from bc_idcard;
delete from bs_temp_driver where id in (10159034,10159032);
delete from bs_temp_driver_workflow;
delete from bs_temp_driver where id=10150592;
-- update bs_temp_driver set valid_start_date = null;

-- 查询
SELECT b.*,a.* FROM bc_idcard a left join bc_idcard_check b on b.pid=a.id order by b.file_date desc;
SELECT b.*,a.* FROM bc_idcard a left join bc_idcard_pic b on b.pid=a.id order by b.file_date desc;
SELECT * FROM bc_idcard_pic b order by b.file_date desc;
select octet_length(p.data_), p.* from bc_idcard_pic p;
select * from bs_temp_driver order by modified_date desc;
select * from bc_docs_attach where ptype='portrait' and puid='tempDriver.auid.10156240';
update bc_idcard set code='440121222211113333' where id=1;
update bc_idcard_check set file_date='2012-12-13 00:00:01' where id=10156238;
update bc_docs_attach set modified_date='2012-12-13 00:00:00' where ptype='portrait' and puid='tempDriver.auid.10156240';
update bc_idcard_pic set file_date='2012-12-13 00:00:03' where id=1860;
delete from bc_docs_attach where ptype='portrait' and puid='tempDriver.auid.10156240';
update bc_idcard set modified_date=file_date,modifier_id=author_id;

select * from bs_temp_driver order by modified_date desc;
SELECT * FROM bc_idcard_pic b order by b.file_date desc;
select * from bc_docs_attach where ptype='portrait' and puid='tempDriver.auid.10152673';


-- 查询需要同步照片的最新刷卡信息:有身份证图片但司机招聘中的图片较旧的就同步图片
select p.file_date p_file_date,p.type_ p_type,p.data_ p_data
	,c.code d_code,c.name as d_name,d.id d_id,d.uid_ d_uid,a.id as attach_id,a.path attach_path
	,(select h.id from bc_identity_actor_history h where h.current=true and h.actor_id=c.MODIFIER_ID) hid
	from bc_idcard_pic p
	inner join bc_idcard c on c.id=p.pid
	inner join bs_temp_driver d on d.cert_identity=c.code
	left join bc_docs_attach a on a.puid=d.uid_
	where (a.id is null or (a.ptype='portrait' and a.modified_date < p.file_date))
	and not exists (
		select 0 from bc_idcard_pic p1 inner join bc_idcard c1 on c1.id=p1.pid
		where p1.pid = p.pid and p1.file_date > p.file_date
	)
	order by p.file_date asc;
