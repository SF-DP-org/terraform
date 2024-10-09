terraform {
  required_version = ">= 1.8.5"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.121.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key_file_path"
  cloud_id                 = "cloud_id"
  folder_id                = "folder_id"
  zone                     = "ru-central1-a"
}

resource "yandex_compute_image" "ubuntu-image" {
  source_family = "ubuntu-2404-lts-oslogin"
  min_disk_size = 10 
}

resource "yandex_compute_image" "ubuntu-image-srv" {
  source_family = "ubuntu-2404-lts-oslogin"
  min_disk_size = 30
}

resource "yandex_vpc_network" "sf-dp-network" {}

resource "yandex_vpc_subnet" "sf-dp-default-subnet" {
  network_id     = yandex_vpc_network.sf-dp-network.id
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["10.136.11.0/24"]
}

resource "yandex_compute_instance" "kube-master" {
  name     = "sf-dp-kube-master"
  hostname = "sf-dp-kube-master"

  resources {
    cores  = 2
    memory = 8
  }

# Uncomment the section below to make an preemptible instance

  # scheduling_policy {
  #   preemptible = true
  # }

  boot_disk {
    initialize_params {
      image_id = resource.yandex_compute_image.ubuntu-image.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sf-dp-default-subnet.id
    nat    = true
  }
  metadata = {
    ssh-keys  = "admin_user:${file("~/.ssh/id_yandex.pub")}"
    user-data = "#cloud-config\ndatasource:\n Ec2:\n  strct_id: false\nssh_pwauth: no\nusers:\n- name: admin_user\n  sudo: ALL=(ALL) NOPASSWD:ALL\n  shell: /bin/bash\n  ssh_authorized_keys:\n  - ssh-rsa ssh_pubkey\n#cloud-config\nruncmd: []"
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "yandex_compute_instance" "kube-worker" {
  name     = "sf-dp-kube-worker"
  hostname = "sf-dp-kube-worker"

  resources {
    cores  = 2
    memory = 16
  }

# Uncomment the section below to make an preemptible instance

  # scheduling_policy {
  #   preemptible = true
  # }

  boot_disk {
    initialize_params {
      image_id = resource.yandex_compute_image.ubuntu-image.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sf-dp-default-subnet.id
    nat    = true
  }

  metadata = {
    ssh-keys  = "admin_user:${file("~/.ssh/id_yandex.pub")}"
    user-data = "#cloud-config\ndatasource:\n Ec2:\n  strct_id: false\nssh_pwauth: no\nusers:\n- name: admin_user\n  sudo: ALL=(ALL) NOPASSWD:ALL\n  shell: /bin/bash\n  ssh_authorized_keys:\n  - ssh-rsa ssh_pubkey\n#cloud-config\nruncmd: []"
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}

resource "yandex_compute_instance" "srv" {
  name     = "sf-dp-srv"
  hostname = "sf-dp-srv"

  resources {
    cores  = 4
    memory = 16
  }

# Uncomment the section below to make an preemptible instance

  # scheduling_policy {
  #   preemptible = true
  # }

  boot_disk {
    initialize_params {
      image_id = resource.yandex_compute_image.ubuntu-image-srv.id
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.sf-dp-default-subnet.id
    nat    = true
  }
  metadata = {
    ssh-keys  = "admin_user:${file("~/.ssh/id_yandex.pub")}"
    user-data = "#cloud-config\ndatasource:\n Ec2:\n  strct_id: false\nssh_pwauth: no\nusers:\n- name: admin_user\n  sudo: ALL=(ALL) NOPASSWD:ALL\n  shell: /bin/bash\n  ssh_authorized_keys:\n  - ssh-rsa ssh_pubkey\n#cloud-config\nruncmd: []"
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
  
}

output "external_ip_kube-master" {
  value = yandex_compute_instance.kube-master.network_interface[0].nat_ip_address
}
output "external_ip_kube-worker" {
  value = yandex_compute_instance.kube-worker.network_interface[0].nat_ip_address
}
output "external_ip_srv" {
  value = yandex_compute_instance.srv.network_interface[0].nat_ip_address
}

output "local_ip_kube-master" {
  value = yandex_compute_instance.kube-master.network_interface[0].ip_address
}
output "local_ip_kube-worker" {
  value = yandex_compute_instance.kube-worker.network_interface[0].ip_address
}
output "srv_ip_srv" {
  value = yandex_compute_instance.srv.network_interface[0].ip_address
}
