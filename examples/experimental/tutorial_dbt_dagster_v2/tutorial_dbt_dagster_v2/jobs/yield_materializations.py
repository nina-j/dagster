from dagster import AssetMaterialization, Output, job, op
from dagster_dbt.cli import DbtCli, DbtManifest

from ..constants import MANIFEST_PATH

manifest = DbtManifest.read(path=MANIFEST_PATH)
asset_key_by_output_name = {
    output_name: manifest.node_info_to_asset_key(node_info)
    for output_name, node_info in manifest.node_info_by_output_name.items()
}


@op
def my_dbt_build_op(dbt: DbtCli):
    for dagster_event in dbt.cli(["build"], manifest=manifest).stream():
        if isinstance(dagster_event, Output):
            yield AssetMaterialization(
                asset_key=asset_key_by_output_name[dagster_event.output_name],
                metadata=dagster_event.metadata,
            )
        else:
            yield dagster_event

    yield Output(None)


@job
def my_dbt_job():
    my_dbt_build_op()
