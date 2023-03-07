require 'yaml'

class Command

  @err = nil

  def exec(params_from_form)

    save_flag = false

    home = `cd ; pwd`.strip
    `touch #{home}/.rdmfs.yml`

    data = open("#{home}/.rdmfs.yml", 'r') { |f| YAML.load(f) }
    if data == false then
      data = Hash.new
    end

    if params_from_form != nil then
      if params_from_form['act'] == 'mount' then
        if `mount | grep #{params_from_form['mount_path']} | wc -l`.strip == '0' then
          `env RDM_API_URL=#{params_from_form['rdm_api_url']} RDM_NODE_ID=#{params_from_form['rdm_node_id']} RDM_TOKEN=#{params_from_form['rdm_token']} MOUNT_PATH=#{params_from_form['mount_path']} /usr/local/sbin/rdmfs_mount.sh &> /dev/null &`
          `sleep 1`
          data.delete(params_from_form['mount_path'])
          d = Hash.new
          d['rdm_node_id'] = params_from_form['rdm_node_id']
          d['rdm_api_url'] = params_from_form['rdm_api_url']
          d['rdm_token'] = params_from_form['rdm_token']
          data[params_from_form['mount_path']] = d
          save_flag = true
        end
      elsif params_from_form['act'] == 'unmount' then
        `fusermount3 -u #{params_from_form['mount_path']}`
      elsif params_from_form['act'] == 'delete' then
        data.delete(params_from_form['mount_path'])
        save_flag = true
      end
    end

    if save_flag then
      open("#{home}/.rdmfs.yml", 'w') {|f| YAML.dump(data, f) }
    end

    data.each do |k, v|
      mount_action = `mount | grep #{k} | wc -l`.strip == '0' ? 'mount' : 'unmount'
      data[k]['available_action'] = mount_action
    end

    [data, @err]
  end
end
