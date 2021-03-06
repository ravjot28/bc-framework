package cn.bc.form.service;

import java.util.List;

import cn.bc.core.service.CrudService;
import cn.bc.form.domain.Form;

/**
 * 自定义表单Service接口
 * 
 * @author hwx
 * 
 */
public interface FormService extends CrudService<Form> {
	
	/**
	 * 查找指定的表单
	 * @param type 类别
	 * @param pid 其他模块调用此模块时，该模块记录的id
	 * @param code 其他模块调用此模块时，使用的编码
	 * @return
	 */
	public Form findByTPC(String type, Long pid, String code);

	/**
	 * 查找指定类别和pid的表单集合
	 * @param type 类别
	 * @param pid 其他模块调用此模块时，该模块记录的id
	 */
	public List<Form> findList(String type, Long pid);
	
	/**
	 * 查找指定类别和pid的表单集合
	 * @param type 类别
	 * @return
	 */
	public List<Form> findList(String type);

	
}
